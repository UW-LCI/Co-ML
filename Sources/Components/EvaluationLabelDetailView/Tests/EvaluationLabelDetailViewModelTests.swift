// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import Combine
@testable import CoMLApp

final class EvaluationLabelDetailViewModelTests: XCTestCase {

    var databaseStorageService: DatabaseStorageService!
    var firstLabel: LabelAnnotation!
    var lastLabel: LabelAnnotation!
    var evaluationLabelDetailRepository: EvaluationLabelDetailRepository!
    var imageFetchRepository: ImageFetchRepository!

    override func setUp() async throws {
        try await super.setUp()

        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())

        // Create project in which evaluation may be tested.
        let projectID = ProjectID()
        let project = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: project)

        // Add samples to the project's default labels.
        let projectLabels = try {
            let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
            return projectModelInfo.labels
        }()

        // Note: since training is impossible in a test scenario,
        // we don't need to provide interesting training data.
        for label in projectLabels {

            // Add 5 training samples to each label.
            for _ in 0..<5 {
                let labeledImage = LabeledImage(image: anyImage, labelID: label.id)
                try await databaseStorageService.add(labeledImage: labeledImage)
            }
        }

        firstLabel = try XCTUnwrap(projectLabels.first)
        lastLabel = try XCTUnwrap(projectLabels.last)
        XCTAssertNotEqual(firstLabel, lastLabel)

        // Add 1 correct and 1 incorrect test sample to each label.
        let correctFirstLabeledImage = LabeledImage(image: anyImage, labelID: firstLabel.id, dataType: .testing)
        let incorrectFirstLabeledImage = LabeledImage(image: anyImage, labelID: firstLabel.id, dataType: .testing)

        let correctLastLabeledImage = LabeledImage(image: anyImage, labelID: lastLabel.id, dataType: .testing)
        let incorrectLastLabeledImage = LabeledImage(image: anyImage, labelID: lastLabel.id, dataType: .testing)

        for labeledImage in [ correctFirstLabeledImage,
                              incorrectFirstLabeledImage,
                              correctLastLabeledImage,
                              incorrectLastLabeledImage ] {

            try await databaseStorageService.add(labeledImage: labeledImage)
        }

        let predictionsBySampleID: [UUID: Prediction] = [
            correctFirstLabeledImage.sampleID: Prediction(observations: [
                .init(annotation: firstLabel.labelString, confidence: 1.0)
            ]),

            incorrectFirstLabeledImage.sampleID: Prediction(observations: [
                .init(annotation: lastLabel.labelString, confidence: 0.9)
            ]),

            correctLastLabeledImage.sampleID: Prediction(observations: [
                .init(annotation: lastLabel.labelString, confidence: 0.8)
            ]),

            incorrectLastLabeledImage.sampleID: Prediction(observations: [
                .init(annotation: firstLabel.labelString, confidence: 0.7)
            ])
        ]

        let projectModelInfoRepository = ProjectModelInfoRepositoryImpl(
            projectID: projectID,
            databaseStorageService: databaseStorageService)

        imageFetchRepository = ImageFetchRepositoryImpl(databaseStorageService: databaseStorageService)

        let validationRepository = ValidationRepositoryFake(
            projectID: projectID,
            labels: projectLabels,
            classificationTime: .milliseconds(10),
            predictionsBySampleID: predictionsBySampleID
        )

        let evaluationRepository = await EvaluationRepositoryImpl(
            projectID: projectID,
            projectModelInfoRepository: projectModelInfoRepository,
            imageFetchRepository: imageFetchRepository,
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: projectID))

        evaluationLabelDetailRepository = EvaluationLabelDetailRepositoryImpl(
            labelID: firstLabel.id,
            evaluationRepository: evaluationRepository)
    }

    override func tearDown() {
        evaluationLabelDetailRepository = nil
        imageFetchRepository = nil
        lastLabel = nil
        firstLabel = nil
        databaseStorageService = nil
        super.tearDown()
    }

    func testEvaluationLabelDetailViewModel() async throws {

        let viewModel = await EvaluationLabelDetailViewModel(repository: evaluationLabelDetailRepository,
                                                             imageFetchRepository: imageFetchRepository)

        var viewStates = await viewModel.$viewState.values.makeAsyncIterator()

        // first state should be loading.
        let initialState = try await nextState(from: &viewStates)
        guard case .loading = initialState else {
            XCTFail("Unexpected initial state \(initialState)")
            return
        }

        let task = Task {
            await viewModel.monitorProjectChanges()
        }

        let updatedState = try await nextState(from: &viewStates)
        guard case let .loaded(label, cardViewStates) = updatedState else {
            XCTFail("Unexpected updated state \(updatedState)")
            return
        }

        XCTAssertEqual(label, firstLabel)
        XCTAssertEqual(cardViewStates.count, 2)

        let firstCardViewState = try XCTUnwrap(cardViewStates.first)
        guard case let .labeled(firstPredictedLabel, firstCorrect) = firstCardViewState.prediction else {
            XCTFail("Unexpected first card view state \(firstCardViewState)")
            return
        }
        XCTAssertFalse(firstCorrect, "Evaluation sort order requires incorrect card sorted first.")
        XCTAssertEqual(firstPredictedLabel, lastLabel.labelString)

        let lastCardViewState = try XCTUnwrap(cardViewStates.last)
        guard case let .labeled(lastPredictedLabel, lastCorrect) = lastCardViewState.prediction else {
            XCTFail("Unexpected last card view state \(lastCardViewState)")
            return
        }
        XCTAssertTrue(lastCorrect, "Evaluation sort order requires correct card sorted last.")
        XCTAssertEqual(lastPredictedLabel, firstLabel.labelString)

        task.cancel()
    }

    func testEvaluationLabelDetailViewModelHandlesDisappearance() async throws {

        let viewModel = await EvaluationLabelDetailViewModel(repository: evaluationLabelDetailRepository,
                                                             imageFetchRepository: imageFetchRepository)

        var viewStates = await viewModel.$viewState.values.makeAsyncIterator()

        // first state should be loading.
        let initialState = try await nextState(from: &viewStates)
        guard case .loading = initialState else {
            XCTFail("Unexpected initial state \(initialState)")
            return
        }

        let task = Task {
            await viewModel.monitorProjectChanges()
        }

        // Then it should be loaded.
        let updatedState = try await nextState(from: &viewStates)
        guard case .loaded = updatedState else {
            XCTFail("Unexpected updated state \(updatedState)")
            return
        }

        // Now we make the label disappear by deleting it from the database.
        try await databaseStorageService.deleteLabel(id: firstLabel.id)

        let disappearedState = try await nextState(from: &viewStates)
        guard case let .disappeared(lastKnownLabelTitle, lastKnownImageCount) = disappearedState else {
            XCTFail("Unexpected disappeared state \(disappearedState)")
            return
        }

        XCTAssertEqual(lastKnownLabelTitle, "Label 1")
        XCTAssertEqual(lastKnownImageCount, 2)

        task.cancel()
    }
}

// MARK: - Private

private extension EvaluationLabelDetailViewModelTests {

    /// In these tests, the image doesn't matter.
    var anyImage: UIImage {
        .init(systemName: "box.truck.fill")!
    }

    ///
    func nextState(from viewStates: inout AsyncPublisher<Published<EvaluationLabelDetailViewState>.Publisher>.Iterator) async throws -> EvaluationLabelDetailViewState {
        let stateWrapper = await viewStates.next()
        return try XCTUnwrap(stateWrapper)
    }
}
