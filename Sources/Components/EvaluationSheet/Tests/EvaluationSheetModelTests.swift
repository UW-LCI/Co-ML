// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import Combine
@testable import CoMLApp

@MainActor
final class EvaluationSheetModelTests: XCTestCase {
    var databaseStorageService: DatabaseStorageService!
    var sampleDetailRepository: SampleDetailRepository!
    var validationRepository: ValidationRepositoryFake!
    var evaluationDetailRepository: EvaluationDetailRepository!
    var viewModel: EvaluationSheetViewModel!

    var projectID: ProjectID!
    var appleImage: LabeledImage!
    var applesLabel: LabelAnnotation!
    var bananasLabel: LabelAnnotation!

    override func setUp() async throws {
        try await super.setUp()

        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())

        // Add a project.
        projectID = ProjectID()
        let project = Project(id: projectID, title: "Test project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Rename the first project label appropriately.
        let initialProjectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        let label1 = try XCTUnwrap(initialProjectModelInfo.labels.first)
        try await databaseStorageService.update(labelWithID: label1.id, newLabelString: "Apples")

        // Also rename the second label, because both are surfaced in the repository.
        let label2 = try XCTUnwrap(initialProjectModelInfo.labels.last)
        XCTAssertNotEqual(label1.id, label2.id)
        try await databaseStorageService.update(labelWithID: label2.id, newLabelString: "Bananas")

        // Re-fetch, so that our updates may be stored.
        let freshProjectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        applesLabel = try XCTUnwrap(freshProjectModelInfo.labels.first)
        bananasLabel = try XCTUnwrap(freshProjectModelInfo.labels.last)

        // Add an apple sample to test data.
        appleImage = LabeledImage(image: UIImage(systemName: "apple.logo")!,
                                  labelID: applesLabel.id,
                                  dataType: .testing)
        try await databaseStorageService.add(labeledImage: appleImage)

        sampleDetailRepository = SampleDetailRepositoryImpl(
            sampleID: appleImage.sampleID,
            dataType: .testing,
            databaseStorageService: databaseStorageService,
            initialLabelID: applesLabel.id)

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
        evaluationDetailRepository = EvaluationDetailRepositoryImpl(
            sampleID: appleImage.sampleID,
            sampleDetailRepository: sampleDetailRepository,
            validationRepository: validationRepository)

        viewModel = EvaluationSheetViewModel(
            projectID: projectID,
            evaluationDetailsRepository: evaluationDetailRepository,
            imageFetchRepository: ImageFetchRepositoryFake(
                imagesBySampleID: [appleImage.sampleID: appleImage.image]
            )
        )
    }

    func testViewStateStream() async throws {
        var viewStates = viewModel.$viewState.values.makeAsyncIterator()

        let initialStateWrapper = await viewStates.next()
        let initialState = try XCTUnwrap(initialStateWrapper)
        XCTAssertNil(initialState)

        let monitoringTask = Task {
            await viewModel.monitorChanges()
        }

        let updatedState = try await nextState(from: &viewStates)

        XCTAssertEqual(updatedState.sampleID, appleImage.sampleID)
        guard case let .predicted(descriptiveLabelState, observations) = updatedState.predictionState else {
            XCTFail("Unexpected prediction state \(updatedState.predictionState)")
            return
        }
        XCTAssertEqual(descriptiveLabelState, .correct(labelName: "Apples"))
        XCTAssertEqual(updatedState.selectedLabelID, applesLabel.id)
        XCTAssertEqual(updatedState.labels, [
            applesLabel,
            bananasLabel
        ])
        XCTAssertEqual(observations.map({ $0.annotation }), [
            "Apples",
            "Bananas"
        ])
        XCTAssertEqual(observations.map({ $0.confidence }), [
            0.7,
            0.2
        ])

        monitoringTask.cancel()
    }

    func testLabelChangeMakesCorrectDescriptionIncorrect() async throws {
        var viewStates = viewModel.$viewState.values.makeAsyncIterator()

        let initialStateWrapper = await viewStates.next()
        let initialState = try XCTUnwrap(initialStateWrapper)
        XCTAssertNil(initialState)

        let monitoringTask = Task {
            await viewModel.monitorChanges()
        }

        // Grab the 2nd state, which is tested above, and verify the initial description.
        let updatedState = try await nextState(from: &viewStates)
        guard case let .predicted(descriptiveLabelState, _) = updatedState.predictionState else {
            XCTFail("Unexpected prediction state \(updatedState.predictionState)")
            return
        }
        XCTAssertEqual(descriptiveLabelState, .correct(labelName: "Apples"))

        // Tell the view model to change the label.
        viewModel.changeExpectedLabel(labelID: bananasLabel.id)
        let thirdState = try await nextState(from: &viewStates)
        guard case let .predicted(thirdDescriptiveLabelState, _) = thirdState.predictionState else {
            XCTFail("Unexpected prediction state \(thirdState.predictionState)")
            return
        }
        XCTAssertEqual(thirdDescriptiveLabelState, .incorrect(
            wrongLabelName: "Apples",
            expectedLabelName: "Bananas"))

        monitoringTask.cancel()
    }

    func testViewStateStreamOmitsTooManyConfidences() async throws {
        var viewStates = viewModel.$viewState.values.makeAsyncIterator()

        let initialStateWrapper = await viewStates.next()
        let initialState = try XCTUnwrap(initialStateWrapper)
        XCTAssertNil(initialState)

        // Set the predictions to more than 3, with no zero confidences. The bottom one should be omitted.
        await validationRepository.updatePredictionsBySampleID(predictionsBySampleID: [
            appleImage.sampleID: Prediction(observations: [
                Observation(annotation: "Apples", confidence: 0.4),
                Observation(annotation: "Bananas", confidence: 0.15),
                Observation(annotation: "Carrots", confidence: 0.07),
                Observation(annotation: "Oranges", confidence: 0.03),
            ])
        ])

        let monitoringTask = Task {
            await viewModel.monitorChanges()
        }

        let updatedState = try await nextState(from: &viewStates)

        XCTAssertEqual(updatedState.sampleID, appleImage.sampleID)
        guard case let .predicted(_, observations) = updatedState.predictionState else {
            XCTFail("Unexpected prediction state \(updatedState.predictionState)")
            return
        }
        XCTAssertEqual(observations.map({ $0.annotation }), [
            "Apples",
            "Bananas",
            "Carrots" // Note: "Oranges" is omitted.
        ])
        XCTAssertEqual(observations.map({ $0.confidence }), [
            0.4,
            0.15,
            0.07 // Note: "0.03" is omitted.
        ])

        monitoringTask.cancel()
    }

    func testViewStateStreamOmitsZeroConfidences() async throws {
        var viewStates = viewModel.$viewState.values.makeAsyncIterator()

        let initialStateWrapper = await viewStates.next()
        let initialState = try XCTUnwrap(initialStateWrapper)
        XCTAssertNil(initialState)

        // Set the predictions to more than 3, with some "zero" confidences. The bottom one should be omitted.
        await validationRepository.updatePredictionsBySampleID(predictionsBySampleID: [
            appleImage.sampleID: Prediction(observations: [
                Observation(annotation: "Apples", confidence: 0.4),
                Observation(annotation: "Bananas", confidence: 0.005),
                Observation(annotation: "Carrots", confidence: 0.004_999),
                Observation(annotation: "Oranges", confidence: 0.0),
                Observation(annotation: "Yams", confidence: 0.0),
            ])
        ])

        let monitoringTask = Task {
            await viewModel.monitorChanges()
        }

        let updatedState = try await nextState(from: &viewStates)

        XCTAssertEqual(updatedState.sampleID, appleImage.sampleID)
        guard case let .predicted(_, observations) = updatedState.predictionState else {
            XCTFail("Unexpected prediction state \(updatedState.predictionState)")
            return
        }
        XCTAssertEqual(observations.map({ $0.annotation }), [ "Apples", "Bananas" ])
        XCTAssertEqual(observations.map({ $0.confidence }), [ 0.4, 0.005 ])

        monitoringTask.cancel()
    }

    // MARK: - Helpers

    func nextState(from viewStates: inout AsyncPublisher<Published<EvaluationSheetViewState?>.Publisher>.Iterator) async throws -> EvaluationSheetViewState {
        let stateWrapper = await viewStates.next()
        let stateOptional = try XCTUnwrap(stateWrapper)
        return try XCTUnwrap(stateOptional)
    }
}
