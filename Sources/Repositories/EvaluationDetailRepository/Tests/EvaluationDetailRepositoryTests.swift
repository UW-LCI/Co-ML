// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class EvaluationDetailRepositoryTests: XCTestCase {
    var databaseStorageService: DatabaseStorageService!
    var sampleDetailRepository: SampleDetailRepository!
    var validationRepository: ValidationRepository!
    var evaluationDetailRepository: EvaluationDetailRepository!

    var projectID: ProjectID!
    var appleImage: LabeledImage!
    var applesLabelID: LabelID!
    var bananasLabelID: LabelID!

    override func setUp() async throws {
        try await super.setUp()

        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())

        // Add a project.
        projectID = ProjectID()
        let project = Project(id: projectID, title: "Test project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Rename the first project label appropriately.
        let initialProjectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        applesLabelID = try XCTUnwrap(initialProjectModelInfo.labels.first?.id)
        try await databaseStorageService.update(labelWithID: applesLabelID, newLabelString: "Apples")

        // Also rename the second label, because both are surfaced in the repository.
        bananasLabelID = try XCTUnwrap(initialProjectModelInfo.labels.last?.id)
        XCTAssertNotEqual(applesLabelID, bananasLabelID)
        try await databaseStorageService.update(labelWithID: bananasLabelID, newLabelString: "Bananas")

        // Add an apple sample to test data.
        appleImage = LabeledImage(image: UIImage(systemName: "apple.logo")!,
                                      labelID: applesLabelID,
                                      dataType: .testing)
        try await databaseStorageService.add(labeledImage: appleImage)

        sampleDetailRepository = SampleDetailRepositoryImpl(sampleID: appleImage.sampleID,
                                                            dataType: .testing,
                                                            databaseStorageService: databaseStorageService,
                                                            initialLabelID: applesLabelID)

        // Specify what the prediction will be for the Apple image.
        validationRepository = ValidationRepositoryFake(
            projectID: projectID,
            labels: initialProjectModelInfo.labels,
            classificationTime: .milliseconds(10),
            predictionsBySampleID: [
                appleImage.sampleID: Prediction(observations: [
                    Observation(annotation: "Apples", confidence: 0.7),
                    Observation(annotation: "Bananas", confidence: 0.2)
                ])
            ]
        )

        // Finally, set up the evaluation detail repository.
        evaluationDetailRepository = EvaluationDetailRepositoryImpl(sampleID: appleImage.sampleID,
                                                                    sampleDetailRepository: sampleDetailRepository,
                                                                    validationRepository: validationRepository)
    }

    func testEvaluationDetailsFetch() async throws {
        // Compare the labels returned from the evaluation repository to the project model info source of truth.
        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)

        // Ask the repository for evaluation details, and verify they are as expected.
        let evaluationDetails = try await evaluationDetailRepository.fetchEvaluationDetails()
        XCTAssertEqual(evaluationDetails.image.imageID, appleImage.id)
        XCTAssertEqual(evaluationDetails.labels, projectModelInfo.labels)
        XCTAssertEqual(evaluationDetails.expectedLabelID, applesLabelID)

        let predictionState = try XCTUnwrap(evaluationDetails.image.predictionState)
        XCTAssertTrue(predictionState.isCorrect)
    }

    func testEvaluationDetailsReturnsIncorrectAfterExpectedLabelChange() async throws {
        try await evaluationDetailRepository.changeExpectedLabel(labelID: bananasLabelID)
        let evaluationDetails = try await evaluationDetailRepository.fetchEvaluationDetails()
        let predictionState = try XCTUnwrap(evaluationDetails.image.predictionState)
        XCTAssertFalse(predictionState.isCorrect)
    }

    func testSetupConditions() async throws {
        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        XCTAssertEqual(projectModelInfo.sampleIDsByLabelUUID[applesLabelID.id]?.count, 0)
        XCTAssertEqual(projectModelInfo.testSampleIDsByLabelUUID[applesLabelID.id]?.count, 1)
    }

    func testEvaluationRepositoryDelete() async throws {
        try await evaluationDetailRepository.deleteSample()
        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        XCTAssertEqual(projectModelInfo.sampleIDsByLabelUUID[applesLabelID.id]?.count, 0)
        XCTAssertEqual(projectModelInfo.testSampleIDsByLabelUUID[applesLabelID.id]?.count, 0)
    }

    func testEvaluationRepositoryMove() async throws {
        try await evaluationDetailRepository.moveToTrainingData()
        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        XCTAssertEqual(projectModelInfo.sampleIDsByLabelUUID[applesLabelID.id]?.count, 1)
        XCTAssertEqual(projectModelInfo.testSampleIDsByLabelUUID[applesLabelID.id]?.count, 0)
    }
}
