// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import Foundation
import os.log

@MainActor
final class EvaluationRepositoryImpl: EvaluationRepository {
    let projectID: ProjectID
    private let projectModelInfoRepository: ProjectModelInfoRepository
    private let imageFetchRepository: ImageFetchRepository
    private let validationRepository: ValidationRepository
    private let modelStorageService: ModelStorageService

    init(projectID: ProjectID,
         projectModelInfoRepository: ProjectModelInfoRepository,
         imageFetchRepository: ImageFetchRepository,
         validationRepository: ValidationRepository,
         modelStorageService: ModelStorageService) {
        self.projectID = projectID
        self.projectModelInfoRepository = projectModelInfoRepository
        self.imageFetchRepository = imageFetchRepository
        self.validationRepository = validationRepository
        self.modelStorageService = modelStorageService
    }

    // MARK: - EvaluationRepository

    func evaluate() async -> EvaluationRepositoryState {

        do {
            let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
            let sortedLabels = projectModelInfo.labels

            // Start by populating all the not-yet-evaluated images into a grid view state.
            let sampleIDsByLabelUUID = projectModelInfo.testSampleIDsByLabelUUID

            let imageIDsByLabelID = sampleIDsByLabelUUID.joinedImageIDsByLabelID(with: Set(sortedLabels.map({ $0.id })))
            let noEvaluatedImages = imageIDsByLabelID.withNoneEvaluated

            let isModelOutOfDate: Bool
            if let latestModelInfo = await modelStorageService.fetchModelInfo()?.projectModelInfo {
                isModelOutOfDate = !projectModelInfo.changes(since: latestModelInfo).isEmpty
            } else {
                isModelOutOfDate = false
            }

            // Try to load the model, and if it fails, send a final, no-model state.
            do {
                try await validationRepository.loadModel()
            } catch {
                os_log(.info, "Couldn't load the model, probably because it doesn't exist: \(error)")
                return EvaluationRepositoryState(projectID: projectID,
                                                 isModelOutOfDate: isModelOutOfDate,
                                                 sortedLabels: sortedLabels,
                                                 imagesByLabelID: noEvaluatedImages,
                                                 noModel: true)
            }

            do {
                let result = try await evaluatedState(isModelOutOfDate: isModelOutOfDate,
                                                      sortedLabels: sortedLabels,
                                                      imageIDsByLabelID: imageIDsByLabelID)
                return result

            } catch {
                // Ignore evaluation errors at this point, because they will clear the grid.
                os_log(.error, "An error occurred validating the model: \(error)")

                // Send the final state for consumption by sidebar.
                let noEvaluatedImages = imageIDsByLabelID.withNoneEvaluated
                return EvaluationRepositoryState(projectID: projectID,
                                                 isModelOutOfDate: isModelOutOfDate,
                                                 sortedLabels: sortedLabels,
                                                 imagesByLabelID: noEvaluatedImages)
            }

        } catch {
            os_log(.error, "An error occurred evaluating: \(error)")
            return .failed(error)
        }
    }

    /// Evaluates all images in our local cache, publishing to the parameterized continuation when done, or at least
    /// once per every `yieldInterval` seconds elapsed.
    ///
    /// The validation repository model is expected to be loaded before this is called, or else it will throw.
    ///
    /// We iterate column by column, evaluating as follows:
    ///   - label1.images[0], label2.images[0], label3.images[0], ...
    ///   - label1.images[1], label2,images[1], etc.
    ///
    /// Doing this ensures that evaluation results are quickly displayed on screen, because each label
    /// is displayed in a row, and only a handful are immediately visible without scrolling.
    private func evaluatedState(isModelOutOfDate: Bool,
                                sortedLabels: [LabelAnnotation],
                                imageIDsByLabelID: [LabelID: [LabeledImageID]]) async throws -> EvaluationRepositoryState {

        var predictionsByImageID: [LabeledImageID: Prediction] = [:]
        var numImagesEvaluated = 0

        // For each label, evaluate all images.
        let dt = try await ContinuousClock().measure {

            for label in sortedLabels {
                let imageIDs = imageIDsByLabelID[label.id] ?? []
                for imageID in imageIDs {
                    let image = try await imageFetchRepository.fetchImage(sampleUUID: imageID.sampleID)
                    let labeledImage = LabeledImage(existingLabeledImageID: imageID,
                                                    image: image,
                                                    creationDate: Date(),
                                                    dataType: .testing)
                    let prediction = try await validationRepository.classify(labeledImage: labeledImage)
                    predictionsByImageID[imageID] = prediction
                    numImagesEvaluated += 1
                }
            }
        }

        os_log(.info, "Evaluated \(numImagesEvaluated) images after \(dt).")
        let evaluatedImages = imageIDsByLabelID.evaluated(predictionsByImageID: predictionsByImageID,
                                                          labels: sortedLabels)

        return EvaluationRepositoryState(projectID: projectID,
                                         isModelOutOfDate: isModelOutOfDate,
                                         sortedLabels: sortedLabels,
                                         imagesByLabelID: evaluatedImages)
    }
}

extension EvaluationRepositoryState {

    /// Initializes an evaluation repository state.
    /// - Parameters:
    ///   - projectID: The project ID associated with the repository state.
    ///   - sortedLabels: The sorted LabelAnnotations corresponding to this state.
    ///   - imagesByLabelID: The sorted images, keyed by their label ID, each joined
    ///                      with a prediction if available.
    ///   - final: Whether this is the final state or not.
    init(projectID: ProjectID,
         isModelOutOfDate: Bool,
         sortedLabels: [LabelAnnotation],
         imagesByLabelID: [LabelID: [EvaluatedImage]],
         noModel: Bool = false) {

        let evaluationRepositoryInfo = EvaluationRepositoryInfo(
            projectID: projectID,
            isModelOutOfDate: isModelOutOfDate,
            sortedLabels: sortedLabels,
            imagesByLabelID: imagesByLabelID)

        if noModel {
            self = .noModel(evaluationRepositoryInfo)
            return
        }

        self = .evaluationCompleted(evaluationRepositoryInfo)
    }
}

private extension Dictionary where Key == UUID, Value == [UUID] {

    /// Converts the receiver to a dictionary with label and project-aware types.
    /// - Parameter labelIDs: The set of LabelIDs used to build the result.
    /// - Returns: A dictionary whose keys are project-aware `LabelIDs`, and whose values are label-aware `LabeledImageIDs`.
    func joinedImageIDsByLabelID(with labelIDs: Set<LabelID>) -> [LabelID: [LabeledImageID]] {

        var result: [LabelID: [LabeledImageID]] = [:]

        for (labelUUID, sampleUUIDs) in self {

            guard let labelID = labelIDs.first(where: { $0.id == labelUUID }) else {
                assertionFailure("Label UUID \(labelUUID) missing from project label IDs set \(labelIDs)")
                continue
            }

            let imageIDs = sampleUUIDs.map { LabeledImageID(existingSampleID: $0, labelID: labelID) }

            result[labelID] = imageIDs
        }

        return result
    }
}
