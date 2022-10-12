// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

actor EvaluationDetailRepositoryImpl: EvaluationDetailRepository {
    let sampleID: UUID
    private let sampleDetailRepository: SampleDetailRepository
    private let validationRepository: ValidationRepository

    init(sampleID: UUID, sampleDetailRepository: SampleDetailRepository, validationRepository: ValidationRepository) {
        self.sampleID = sampleID
        self.sampleDetailRepository = sampleDetailRepository
        self.validationRepository = validationRepository
    }

    func fetchEvaluationDetails() async throws -> EvaluationDetails {
        // Fetch and explode the sample details.
        let sampleDetails = try await sampleDetailRepository.fetchSampleDetails()
        let (labeledImage, expectedLabelID, labels) = (
            sampleDetails.image,
            sampleDetails.selectedLabelID,
            sampleDetails.labels
        )

        do {
            try await validationRepository.loadModel()
        } catch {
            os_log(.info, "No model could be loaded, so returning the unevaluated image.")
            let unevaluatedImage = EvaluatedImage(imageID: labeledImage.id, predictionState: nil)
            return EvaluationDetails(image: unevaluatedImage,
                                     labels: labels,
                                     expectedLabelID: expectedLabelID)
        }

        // Classify the sample details.
        let prediction = try await validationRepository.classify(labeledImage: labeledImage)
        let isCorrect = prediction.isCorrect(labelID: expectedLabelID, labels: labels)
        let predictionState = EvaluatedImage.PredictionState(prediction: prediction, isCorrect: isCorrect)
        let evaluatedImage = EvaluatedImage(imageID: labeledImage.id, predictionState: predictionState)

        // Re-build the result into an `EvaluationDetails` instance.
        let result = EvaluationDetails(image: evaluatedImage,
                                       labels: labels,
                                       expectedLabelID: expectedLabelID)
        return result
    }

    func changeExpectedLabel(labelID: LabelID) async throws {
        try await sampleDetailRepository.updateSelectedLabel(labelID: labelID)
    }

    func deleteSample() async throws {
        try await sampleDetailRepository.deleteSample()
    }

    func moveToTrainingData() async throws {
        try await sampleDetailRepository.moveToOppositeDataType()
    }
}
