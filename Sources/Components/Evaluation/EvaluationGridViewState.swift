// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct EvaluationGridViewState {
    let projectID: ProjectID
    let isModelOutOfDate: Bool
    let evaluationRibbonViewStates: [EvaluationRibbonViewState]
}

extension EvaluationGridViewState {

    var labelRibbonViewStates: [LabelRibbonViewState] {
        evaluationRibbonViewStates.map(\.labelRibbonViewState)
    }

    func prediction(labeledImageID: LabeledImageID) -> GradedCardViewState.Prediction {
        guard let evaluatedImage = evaluatedImage(labeledImageID) else {
            return .blank
        }
        guard let predictionState = evaluatedImage.predictionState else {
            return .blank
        }
        guard let topPrediction = predictionState.prediction.observations.first else {
            return .blank
        }
        let predictedLabel = topPrediction.annotation

        return .labeled(predictedLabel: predictedLabel,
                        correct: predictionState.isCorrect)
    }
}

struct EvaluationRibbonViewState {
    let label: LabelAnnotation
    let images: [EvaluatedImage]
}

// MARK: - Private

private extension EvaluationGridViewState {
    func evaluatedImage(_ labeledImageID: LabeledImageID) -> EvaluatedImage? {
        allImages.first { $0.imageID == labeledImageID }
    }

    var allImages: [EvaluatedImage] {
        evaluationRibbonViewStates.flatMap { $0.images }
    }
}

private extension EvaluationRibbonViewState {
    var labelRibbonViewState: LabelRibbonViewState {
        LabelRibbonViewState(label: label,
                             imageList: images.map({ $0.imageID.sampleID }),
                             imageCount: images.count)
    }
}

#if DEBUG

extension EvaluationGridViewState {

    static let fake: Self = .init(
        projectID: .fakeProjectID,
        isModelOutOfDate: true,
        evaluationRibbonViewStates: .fakeApplesAndBananas
    )
}

extension [EvaluationRibbonViewState] {

    static let fakeApplesAndBananas: Self = [
        .fakeApplesRibbon,
        .fakeBananasRibbon
    ]
}

extension EvaluationRibbonViewState {

    static let fakeApplesRibbon: Self = .init(
        label: .fakeAppleLabel,
        images: .fakeAppleEvaluatedImages
    )

    static let fakeBananasRibbon: Self = .init(
        label: .fakeBananaLabel,
        images: .fakeBananaEvaluatedImages
    )
}

#endif
