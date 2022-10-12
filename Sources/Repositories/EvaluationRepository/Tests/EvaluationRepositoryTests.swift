// Copyright 2026 Apple Inc. All rights reserved.

@testable import CoMLApp
import XCTest

@MainActor
final class EvaluationRepositoryTests: XCTestCase {

    static let apple1 = LabeledImage(
        existingLabeledImageID: .fakeApple1id,
        image: UIImage(systemName: "box.truck")!,
        creationDate: .date1,
        dataType: .testing)

    static let apple2 = LabeledImage(
        existingLabeledImageID: .fakeApple2id,
        image: UIImage(systemName: "box.truck")!,
        creationDate: .date2,
        dataType: .testing)

    static let banana1 = LabeledImage(
        existingLabeledImageID: .fakeBanana1id,
        image: UIImage(systemName: "sun.min")!,
        creationDate: .date5,
        dataType: .testing)

    static let labelAnnotations: [LabelAnnotation] = [
        .fakeAppleLabel,
        .fakeBananaLabel,
        .fakeCarrotLabel
    ]

    static let labeledImages = [
        apple1,
        apple2,
        banana1,
    ]

    var projectModelInfoRepository: ProjectModelInfoRepository!
    var imageFetchRepository: ImageFetchRepository!
    var validationRepository: ValidationRepository!
    var evaluationRepository: EvaluationRepository!

    override func setUp() {
        super.setUp()
        projectModelInfoRepository = ProjectModelInfoRepositoryFake(
            projectID: .fakeProjectID,
            projectModelInfo: ProjectModelInfo(
                version: "1.1",
                labels: Self.labelAnnotations,
                sampleIDsByLabelUUID: [
                    .fakeAppleLabelUUID: [],
                    .fakeBananaLabelUUID: [],
                    .fakeCarrotLabelUUID: []
                ],
                testSampleIDsByLabelUUID: [
                    .fakeAppleLabelUUID: [
                        Self.apple1.sampleID,
                        Self.apple2.sampleID
                    ],
                    .fakeBananaLabelUUID: [
                        Self.banana1.sampleID
                    ],
                    .fakeCarrotLabelUUID: [
                    ]
                ]))

        imageFetchRepository = ImageFetchRepositoryFake()
        validationRepository = ValidationRepositoryFake(projectID: .fakeProjectID)

        evaluationRepository = EvaluationRepositoryImpl(
            projectID: .fakeProjectID,
            projectModelInfoRepository: projectModelInfoRepository,
            imageFetchRepository: imageFetchRepository,
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: .fakeProjectID)
        )
    }

    func testEvaluationRepositoryPublishesNoModelState() async throws {

        let evaluationState = await evaluationRepository.evaluate()

        guard case let .noModel(info) = evaluationState else {
            XCTFail("Unexpected state \(evaluationState)")
            return
        }

        XCTAssertEqual(info.sortedLabels, Self.labelAnnotations)
        XCTAssertEqual(info.allImages.count, 3)
    }

    func testEvaluationRepositorySortsIncorrectPredictionsFirst() async throws {

        // Configure the fake validation repository with specific predictions for our labeled images.
        validationRepository = ValidationRepositoryFake(
            projectID: .fakeProjectID,
            labels: Self.labelAnnotations,
            classificationTime: .milliseconds(10),

            // N.B. it is not possible to leave out predictions, because the `ValidationRepository` API contract claims
            // to either `validate` or `throw` -- we don't need to handle throwing in this unit test.
            predictionsBySampleID: [
                // A CORRECT prediction which should be sorted last.
                Self.apple1.sampleID: Prediction(observations: [
                    Observation(annotation: LabelAnnotation.fakeAppleLabel.labelString, confidence: 0.8)
                ]),

                // An INCORRECT prediction which should be sorted first.
                Self.apple2.sampleID: Prediction(observations: [
                    Observation(annotation: LabelAnnotation.fakeBananaLabel.labelString, confidence: 0.8)
                ]),
            ]
        )

        evaluationRepository = EvaluationRepositoryImpl(
            projectID: .fakeProjectID,
            projectModelInfoRepository: projectModelInfoRepository,
            imageFetchRepository: imageFetchRepository,
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: .fakeProjectID))

        let evaluationState = await evaluationRepository.evaluate()

        guard case let .evaluationCompleted(info) = evaluationState else {
            XCTFail("Evaluation state \(evaluationState) expected to be completed.")
            return
        }

        XCTAssertEqual(info.sortedLabels, Self.labelAnnotations)
        XCTAssertEqual(info.allImages.count, 3)

        let sortedEvaluatedApples = try XCTUnwrap(info.imagesByLabelID[LabelAnnotation.fakeAppleLabel.id])
        XCTAssertEqual(sortedEvaluatedApples.count, 2)

        // Verify the order is correct.
        let firstApple = try XCTUnwrap(sortedEvaluatedApples.first)
        XCTAssertTrue(firstApple.hasPrediction)
        XCTAssertFalse(firstApple.isCorrect)

        let lastApple = try XCTUnwrap(sortedEvaluatedApples.last)
        XCTAssertTrue(lastApple.hasPrediction)
        XCTAssertTrue(lastApple.isCorrect)
    }
}
