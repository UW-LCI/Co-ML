// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Joins a labeled image with its predictions, if available.
struct EvaluatedImage: Sendable {
    struct PredictionState: Sendable {
        let prediction: Prediction
        let isCorrect: Bool
    }

    /// The image ID that is, or will be, evaluated.
    let imageID: LabeledImageID

    /// The image's associated predictions.
    let predictionState: PredictionState?

    /// Convenience accessor for correctness. Returns false for images with no prediction.
    var isCorrect: Bool {
        predictionState?.isCorrect ?? false
    }

    /// Convenience accessor returning whether this evaluated image has any prediction.
    var hasPrediction: Bool {
        predictionState != nil
    }
}

#if DEBUG

extension [EvaluatedImage] {

    static let fakeAppleEvaluatedImages: Self = [
        .fakeApple1,
        .fakeApple2,
        .fakeApple3,
        .fakeApple4
    ]

    static let fakeBananaEvaluatedImages: Self = [
        .fakeBanana1,
        .fakeBanana2,
        .fakeBanana3
    ]
}

extension EvaluatedImage {

    static let fakeApple1: Self = .init(
        imageID: .fakeApple1id,
        predictionState: .fakeIncorrect(annotation: .fakeBananaLabelString, confidence: 1.0)
    )

    static let fakeApple2: Self = .init(
        imageID: .fakeApple2id,
        predictionState: .fakeIncorrect(annotation: .fakeBananaLabelString, confidence: 1.0)
    )

    static let fakeApple3: Self = .init(
        imageID: .fakeApple3id,
        predictionState: .fakeCorrect(annotation: .fakeAppleLabelString, confidence: 0.65)
    )

    static let fakeApple4: Self = .init(
        imageID: .fakeApple4id,
        predictionState: .fakeCorrect(annotation: .fakeAppleLabelString, confidence: 0.78)
    )

    static let fakeBanana1: Self = .init(
        imageID: .fakeBanana1id,
        predictionState: .fakeIncorrect(annotation: .fakeAppleLabelString, confidence: 0.43)
    )

    static let fakeBanana2: Self = .init(
        imageID: .fakeBanana2id,
        predictionState: .fakeCorrect(annotation: .fakeBananaLabelString, confidence: 0.61)
    )

    static let fakeBanana3: Self = .init(
        imageID: .fakeBanana3id,
        predictionState: .fakeCorrect(annotation: .fakeBananaLabelString, confidence: 0.74)
    )
}

extension EvaluatedImage.PredictionState {
    static func fakeCorrect(annotation: String, confidence: Double) -> Self {
        .init(
            prediction: .fakeSingleObservation(annotation: annotation, confidence: confidence),
            isCorrect: true
        )
    }

    static func fakeIncorrect(annotation: String, confidence: Double) -> Self {
        .init(
            prediction: .fakeSingleObservation(annotation: annotation, confidence: confidence),
            isCorrect: false
        )
    }
}

extension Prediction {
    static func fakeSingleObservation(annotation: String, confidence: Double) -> Self {
        .init(
            observations: [
                Observation(annotation: annotation, confidence: confidence)
            ]
        )
    }
}

#endif
