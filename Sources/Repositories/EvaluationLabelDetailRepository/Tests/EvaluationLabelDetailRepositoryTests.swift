// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import XCTest
@testable import CoMLApp

final class EvaluationLabelDetailRepositoryTests: XCTestCase {

    var evaluationRepository: EvaluationRepository!

    override func setUp() async throws {
        try await super.setUp()

        let applesLabelString = LabelAnnotation.fakeAppleLabel.labelString
        let bananasLabelString = LabelAnnotation.fakeBananaLabel.labelString

        evaluationRepository = await EvaluationRepositoryFake(
            projectID: .fakeProjectID,
            stateToPublish: EvaluationRepositoryState(
                projectID: .fakeProjectID,
                isModelOutOfDate: false,
                sortedLabels: [
                    .fakeAppleLabel,
                    .fakeBananaLabel
                ],

                imagesByLabelID: [

                    .fakeAppleLabelID: [
                        EvaluatedImage(imageID: .fakeApple1id, annotation: bananasLabelString, correct: false),
                        EvaluatedImage(imageID: .fakeApple2id, annotation: bananasLabelString, correct: false),
                        EvaluatedImage(imageID: .fakeApple3id, annotation: applesLabelString, correct: true),
                        EvaluatedImage(imageID: .fakeApple4id, annotation: applesLabelString, correct: true),
                        EvaluatedImage(imageID: .fakeApple5id, annotation: applesLabelString, correct: true),
                    ],

                    .fakeBananaLabelID: [
                        EvaluatedImage(imageID: .fakeBanana1id, annotation: applesLabelString, correct: false),
                        EvaluatedImage(imageID: .fakeBanana2id, annotation: applesLabelString, correct: false),
                        EvaluatedImage(imageID: .fakeBanana3id, annotation: applesLabelString, correct: false),
                        EvaluatedImage(imageID: .fakeBanana4id, annotation: applesLabelString, correct: false),
                        EvaluatedImage(imageID: .fakeBanana5id, annotation: applesLabelString, correct: true),
                        EvaluatedImage(imageID: .fakeBanana6id, annotation: bananasLabelString, correct: true)
                    ]
                ]))
    }

    func testApplesRepositoryFetchProvidesExpectedNumberOfCardViewStates() async {
        let evaluationLabelDetailRepository = EvaluationLabelDetailRepositoryImpl(
            labelID: .fakeAppleLabelID,
            evaluationRepository: evaluationRepository
        )

        let state = await evaluationLabelDetailRepository.fetchEvaluationLabelDetailViewState()

        guard case let .loaded(label, cardViewStates) = state else {
            XCTFail("Evaluation label detail repository produced unexpected state \(state)")
            return
        }

        XCTAssertEqual(label, .fakeAppleLabel)
        XCTAssertEqual(cardViewStates.count, 5)
    }

    func testCarrotsRepositoryFetchFailsWithLabelDisappearedState() async {
        let evaluationLabelDetailRepository = EvaluationLabelDetailRepositoryImpl(
            labelID: .fakeCarrotLabelID,
            evaluationRepository: evaluationRepository
        )

        let state = await evaluationLabelDetailRepository.fetchEvaluationLabelDetailViewState()

        guard case let .disappeared(lastKnownLabelTitle, lastKnownImageCount) = state else {
            XCTFail("Evaluation label detail repository produced unexpected state \(state)")
            return
        }

        XCTAssertEqual(lastKnownLabelTitle, "Unknown Label")
        XCTAssertEqual(lastKnownImageCount, 0)
    }
}

private extension EvaluatedImage {
    init(imageID: LabeledImageID, annotation: String, correct: Bool) {
        let topObservation = Observation(annotation: annotation, confidence: 1.0)
        let prediction = Prediction(observations: [ topObservation ])
        let predictionState = EvaluatedImage.PredictionState(prediction: prediction, isCorrect: correct)

        self = EvaluatedImage(imageID: imageID, predictionState: predictionState)
    }
}
