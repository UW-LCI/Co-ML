// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit

actor ValidationRepositoryFake: ValidationRepository {
    let projectID: ProjectID
    private let labels: [LabelAnnotation]
    private let classificationTime: Duration

    private(set) var predictionsBySampleID: [UUID: Prediction]

    private var isModelLoaded = false

    init(projectID: ProjectID,
         labels: [LabelAnnotation] = [],
         classificationTime: Duration = .milliseconds(100),
         predictionsBySampleID: [UUID: Prediction] = [:]) {
        self.projectID = projectID
        self.labels = labels
        self.classificationTime = classificationTime
        self.predictionsBySampleID = predictionsBySampleID
    }

    /// Allows updating the predictions list for testing purposes.
    func updatePredictionsBySampleID(predictionsBySampleID: [UUID: Prediction]) async {
        self.predictionsBySampleID = predictionsBySampleID
    }

    // MARK: - ValidationRepository

    func loadModel() async throws {
        if canLoadModel {
            isModelLoaded = true
        } else {
            throw ValidationRepositoryError.modelCompileFailed
        }
    }

    func unloadModel() async {
        isModelLoaded = false
    }

    func classify(labeledImage: LabeledImage) async throws -> Prediction {

        try await Task.sleep(for: classificationTime)

        if let prediction = predictionsBySampleID[labeledImage.sampleID] {
            return prediction
        }

        let sampleUUID = labeledImage.sampleID

        // Use the sample UUID to stably generate a prediction.
        let (hiword, _, _, _, _, _, _, _, _, _, _, _, _, _, _, loword) = sampleUUID.uuid
        let confidence = Double(hiword) / Double(UInt8.max)
        let labelGuessIndex = Int(loword) % labels.count

        // N.B. we only generate a single observation here. It's a lot more work to add a second stable observation, and
        // at this time it wouldn't be used for anything.
        let guessedLabel = labels[labelGuessIndex]
        let result = Prediction(observations: [
            Observation(annotation: guessedLabel.labelString, confidence: confidence)
        ])

        return result
    }

    // MARK: - Private

    private var canLoadModel: Bool {
        !labels.isEmpty
    }
}
