// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import UIKit

@MainActor
final class EvaluationSheetViewModel: ObservableObject {
    let projectID: ProjectID
    private let imageFetchRepository: ImageFetchRepository

    @Published var viewState: EvaluationSheetViewState?
    @Published var isShowingDeleteAlert = false
    @Published var isShowingMoveAlert = false

    init(projectID: ProjectID,
         evaluationDetailsRepository: EvaluationDetailRepository,
         imageFetchRepository: ImageFetchRepository) {

        self.projectID = projectID
        self.evaluationDetailsRepository = evaluationDetailsRepository
        self.imageFetchRepository = imageFetchRepository
    }

    var selectedLabelName: String {
        viewState?.selectedLabelName ?? ""
    }

    var currentDataTypeDescription: String {
        DataType.testing.localizedDescription
    }

    var oppositeDataTypeDescription: String {
        DataType.training.localizedDescription
    }

    func monitorChanges() async {
        await refreshViewState()

        for await _ in NotificationCenter.default.notifications(projectID: projectID) {
            await refreshViewState()
        }
    }

    func changeExpectedLabel(labelID: LabelID) {
        Task(priority: .userInitiated) {
            await changeExpectedLabel(labelID: labelID)
        }
    }

    func moveToOppositeDataType() async throws {
        try await evaluationDetailsRepository.moveToTrainingData()
    }

    func delete() async throws {
        try await evaluationDetailsRepository.deleteSample()
    }

    func fetchImage(_ sampleID: UUID) async throws -> UIImage {
        try await imageFetchRepository.fetchImage(sampleUUID: sampleID)
    }

    // MARK: - Private

    private let evaluationDetailsRepository: EvaluationDetailRepository

    private func refreshViewState() async {
        do {

            let evaluationDetails = try await evaluationDetailsRepository.fetchEvaluationDetails()

            viewState = EvaluationSheetViewState(
                with: evaluationDetails,
                sampleID: evaluationDetailsRepository.sampleID)

        } catch {
            os_log(.error, "Error occurred fetching evaluation details: \(error)")
        }
    }

    private func changeExpectedLabel(labelID: LabelID) async {
        do {
            try await evaluationDetailsRepository.changeExpectedLabel(labelID: labelID)
        } catch {
            os_log(.error, "Error occurred changing label: \(error)")
        }
    }
}

private extension EvaluationSheetViewState {
    init?(with evaluationDetails: EvaluationDetails,
          sampleID: UUID
    ) {

        guard let prediction = evaluationDetails.image.predictionState?.prediction else {
            self = EvaluationSheetViewState(sampleID: sampleID,
                                            predictionState: .noModel,
                                            labels: evaluationDetails.labels,
                                            selectedLabelID: evaluationDetails.expectedLabelID)
            return
        }

        guard let descriptiveLabelState = EvaluationDescriptiveLabelState(
            prediction: prediction,
            expectedLabelID: evaluationDetails.expectedLabelID,
            labels: evaluationDetails.labels
        ) else {
            return nil
        }

        self = EvaluationSheetViewState(
            sampleID: sampleID,
            predictionState: .predicted(
                descriptiveLabelState: descriptiveLabelState,
                observations: prediction.observations.limitedToNonZero(maxCount: 3)),
            labels: evaluationDetails.labels,
            selectedLabelID: evaluationDetails.expectedLabelID)
    }
}

private extension EvaluationDescriptiveLabelState {

    /// Initializes a descriptive label state from the given parameters. Returns `nil` if there is no top observation
    /// to validate against the expected label ID.
    /// - Parameters:
    ///   - prediction: The prediction that will be used to configure the label.
    ///   - expectedLabelID: The label ID used to determine correctness.
    ///   - labels: Used to determine correctness.
    init?(prediction: Prediction,
          expectedLabelID: LabelID,
          labels: [LabelAnnotation]
    ) {
        guard let predictedLabelName = prediction.observations.first?.annotation else {
            return nil
        }

        // Return the "correct" state if possible.
        if prediction.isCorrect(labelID: expectedLabelID, labels: labels) {
            self = .correct(labelName: predictedLabelName)
            return
        }

        // For the incorrect state, we also need the _expected_ label name.
        let expectedLabel = labels.first { $0.id == expectedLabelID }
        guard let expectedLabelName = expectedLabel?.labelString else {
            return nil
        }

        self = .incorrect(wrongLabelName: predictedLabelName,
                          expectedLabelName: expectedLabelName)
    }
}

private extension Array<Observation> {

    /// Restricts the given array to an array of observations with non-zero confidence.
    /// - Parameter maxCount: The max number of observations that may be returned.
    /// - Returns: An array with fewer than or equal to `maxCount` elements, all of which have non-zero confidence.
    func limitedToNonZero(maxCount: Int) -> [Observation] {

        // Note: here, omit confidences that would _round to_ zero.
        let result: [Observation] = filter {
            $0.confidence >= 0.005
        }

        if result.count > maxCount {
            return Array(result[0..<3])
        }

        return result
    }
}
