// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import SwiftUI
import UIKit

@MainActor
final class ClassificationCameraViewModel: ObservableObject {

    deinit {
        os_log(.info, "Deallocating \(#fileID)")
    }

    @Published private(set) var currentLabels: [LabelAnnotation] = []
    @Published private(set) var observations: [Observation] = []
    @Published private(set) var liveStreamedObservations: [Observation] = []
    @Published private(set) var imageCapturedByUser: UIImage?
    @Published var showResultSheet = false
    @Published var isModelOutOfDate = false

    private let projectID: ProjectID
    private let validationRepository: ValidationRepository
    private let classificationImageStreamer: ClassificationImageStreamer
    private let projectModelInfoRepository: ProjectModelInfoRepository
    private let imageRepository: ImageRepository
    private let modelStorageService: ModelStorageService

    init(projectID: ProjectID,
         classificationImageStreamer: ClassificationImageStreamer,
         projectModelInfoRepository: ProjectModelInfoRepository,
         imageRepository: ImageRepository,
         validationRepository: ValidationRepository,
         modelStorageService: ModelStorageService) {
        self.projectID = projectID
        self.classificationImageStreamer = classificationImageStreamer
        self.projectModelInfoRepository = projectModelInfoRepository
        self.imageRepository = imageRepository
        self.validationRepository = validationRepository
        self.modelStorageService = modelStorageService
    }

    var topPredictionResult: Observation? {
        observations.first
    }

    func processPhotoTaken(image: UIImage) async {
        os_log(.info, "Classification received photo taken by user")
        await process(image: image)
    }

    func processClassification() async {
        do {
            os_log(.info, "Starting up classification services")
            try await validationRepository.loadModel()

            os_log(.info, "Start listening for live images for live classification")
            for await observationSet in await classificationImageStreamer.liveObservationsFromCamera() {
                await process(observations: observationSet)
                await checkForModelUpdates()
            }
        } catch {
            os_log(.error, "Unable to start classification")
        }
        os_log(.info, "Stopped listening for live images for live classification")
    }

    func checkForModelUpdates() async {
        let dt = await ContinuousClock().measure {
            await checkForModelUpdatesWithoutProfiling()
        }
        os_log(.debug, "Checked for model updates after \(dt).")
    }

    func checkForModelUpdatesWithoutProfiling() async {
        guard let trainedModelInfo = await modelStorageService.fetchModelInfo()?.projectModelInfo else {
            return
        }
        do {
            let latestModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
            let isModelUpToDate = latestModelInfo.changes(since: trainedModelInfo).isEmpty
            withAnimation {
                isModelOutOfDate = !isModelUpToDate
            }

        } catch {
            os_log(.error, "Error fetching project data in classification camera stream: \(error)")
        }
    }

    func clearResults() {
        withAnimation {
            observations = []
            imageCapturedByUser = nil
        }
    }

    func dismiss() {
        showResultSheet = false
        clearResults()
    }

    var predictionSummaryViewState: PredictionSummaryViewState? {
        if topPredictionResult == nil {
            return nil
        }
        guard let imageCapturedByUser else {
            return nil
        }
        return PredictionSummaryViewState(
            image: imageCapturedByUser,
            observations: observations,
            currentLabels: currentLabels
        )
    }

    func savePhoto(image: UIImage, label: LabelAnnotation?, destination: DataType) {
        Task {
            os_log(.info, "A photo was taken by the user for label '\(label?.labelString ?? "No label")'")
            do {
                if let annotation = label {
                    let labeledImage = LabeledImage(
                        image: image,
                        labelID: annotation.id,
                        dataType: destination
                    )

                    try await imageRepository.add(labeledImage: labeledImage)
                } else {
                    os_log(.error, "Cannot find matching label to save this image")
                }
            } catch let error {
                os_log(.error, "Failed to save photo to repository \(error)")
            }
        }
    }

    // MARK: - Private

    private func process(image: UIImage) async {
        do {
            os_log(.info, "Photo taken! Ready to classify image from user.")
            let labelID = LabelID(id: UUID(), projectID: projectID)
            let labeledImage = LabeledImage(image: image, labelID: labelID)
            let predictionResult = try await validationRepository.classify(labeledImage: labeledImage)
            // fetch latest labels
            let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
            currentLabels = projectModelInfo.labels
            withAnimation {
                observations = predictionResult.observations
                imageCapturedByUser = image
                showResultSheet = true
            }
        } catch {
            os_log(.error, "Error classifying this image: \(error)")
        }
    }

    private func process(observations: CameraPredictionOverlayState) async {
        withAnimation {
            self.liveStreamedObservations = observations
        }
    }
}

#if DEBUG

extension ClassificationCameraViewModel {
    static var fake: ClassificationCameraViewModel {
        let projectID = ProjectID()
        let validationRepository = ValidationRepositoryFake(projectID: projectID)
        let imageStreamer = ClassificationImageStreamer(projectID: projectID,
                                                        validationRepository: validationRepository,
                                                        photoSizer: PhotoSizerImpl())
        return .init(
            projectID: projectID,
            classificationImageStreamer: imageStreamer,
            projectModelInfoRepository: ProjectModelInfoRepositoryFake(projectID: projectID),
            imageRepository: ImageRepositoryFake(projectID: projectID),
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: projectID)
        )
    }
}

#endif
