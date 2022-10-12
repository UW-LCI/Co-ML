// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor EvaluationLabelDetailRepositoryImpl: EvaluationLabelDetailRepository {
    let labelID: LabelID

    private let evaluationRepository: EvaluationRepository
    private var lastKnownLabelTitle = String(localized: .unknownLabel)
    private var lastKnownImageCount = 0

    init(labelID: LabelID, evaluationRepository: EvaluationRepository) {
        self.labelID = labelID
        self.evaluationRepository = evaluationRepository
    }

    // MARK: - EvaluationLabelDetailRepository

    func fetchEvaluationLabelDetailViewState() async -> EvaluationLabelDetailViewState {
        let evaluationState = await evaluationRepository.evaluate()

        switch evaluationState {
        case let .noModel(evaluationRepositoryInfo):
            return evaluationLabelDetailViewState(evaluationRepositoryInfo: evaluationRepositoryInfo, labelID: labelID)

        case let .evaluationCompleted(evaluationRepositoryInfo):
            return evaluationLabelDetailViewState(evaluationRepositoryInfo: evaluationRepositoryInfo, labelID: labelID)

        case .failed:
            return .disappeared(lastKnownLabelTitle: lastKnownLabelTitle,
                                lastKnownImageCount: lastKnownImageCount)
        }
    }
}

// MARK: - Private

private extension EvaluationLabelDetailRepositoryImpl {
    func evaluationLabelDetailViewState(evaluationRepositoryInfo: EvaluationRepositoryInfo,
                                        labelID: LabelID
    ) -> EvaluationLabelDetailViewState {
        let result = EvaluationLabelDetailViewState(evaluationRepositoryInfo: evaluationRepositoryInfo, labelID: labelID)
        guard let result, case let .loaded(label, cardViewStates) = result else {
            return .disappeared(lastKnownLabelTitle: lastKnownLabelTitle,
                                lastKnownImageCount: lastKnownImageCount)
        }
        lastKnownLabelTitle = label.labelString
        lastKnownImageCount = cardViewStates.count
        return result
    }
}

private extension EvaluationLabelDetailViewState {
    init?(evaluationRepositoryInfo: EvaluationRepositoryInfo, labelID: LabelID) {

        let matchingLabel = evaluationRepositoryInfo.sortedLabels.first {
            $0.id == labelID
        }

        guard let matchingLabel else {
            return nil
        }

        let evaluatedImages = evaluationRepositoryInfo.imagesByLabelID[labelID] ?? []
        let cardStates = evaluatedImages.map {
            GradedCardViewState(evaluatedImage: $0, labelID: labelID, labels: evaluationRepositoryInfo.sortedLabels)
        }

        self = .loaded(label: matchingLabel, cardViewStates: cardStates)
    }
}

private extension GradedCardViewState {

    init(evaluatedImage: EvaluatedImage, labelID: LabelID, labels: [LabelAnnotation]) {
        let labelPrediction = evaluatedImage.predictionState?.prediction

        let cardViewPrediction = GradedCardViewState.Prediction(
            labelPrediction: labelPrediction,
            labelID: labelID,
            labels: labels
        )

        self = GradedCardViewState(prediction: cardViewPrediction, imageID: evaluatedImage.imageID)
    }
}

private extension GradedCardViewState.Prediction {
    init(labelPrediction: Prediction?, labelID: LabelID, labels: [LabelAnnotation]) {
        guard let labelPrediction, let topPrediction = labelPrediction.observations.first else {
            self = .blank
            return
        }
        let isCorrect = labelPrediction.isCorrect(labelID: labelID, labels: labels)
        self = .labeled(predictedLabel: topPrediction.annotation, correct: isCorrect)
    }
}
