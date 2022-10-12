// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import XCTest
@testable import CoMLApp

@MainActor
final class TrainingTests: XCTestCase {
    let projectID = ProjectID(uuidString: "1411f478-a920-462c-be16-83e8a74057e1")

    var project: Project!
    var projectModelInfoRepository: ProjectModelInfoRepositoryFake!
    var trainingService: TrainingService!
    var modelStorageService: ModelStorageService!

    var trainingViewModel: TrainingViewModel!

    override func setUp() {
        super.setUp()
        project = Project(id: .fakeProjectID,
                          title: "Test Project",
                          createdAt: Date())

        projectModelInfoRepository = ProjectModelInfoRepositoryFake(
            projectID: .fakeProjectID,
            projectModelInfo: ProjectModelInfo(version: "1.1",
                                               labels: [],
                                               sampleIDsByLabelUUID: [:],
                                               testSampleIDsByLabelUUID: [:]))

        trainingService = .fake // No project model info.
        modelStorageService = .fakeNoModel() // No on-disk model by default.

        trainingViewModel = TrainingViewModel(
            project: project,
            projectModelInfoRepository: projectModelInfoRepository,
            trainingService: trainingService,
            modelStorageService: modelStorageService
        )
    }

    func testTrainingViewGoesUnreadyWithInsufficientModelInfo() async throws {
        // Prepare to observe state changes.
        var states = trainingViewModel.$trainingViewState.values.makeAsyncIterator()

        let initialOptionalState = await states.next()
        let initialState = try XCTUnwrap(initialOptionalState)
        XCTAssertEqual(initialState.projectPanelState, .loading)
        XCTAssertEqual(initialState.modelPanelState, .loading)

        // Refresh training data, yielding an evaluation of project model info.
        let monitorTask = Task {
            await trainingViewModel.monitorProjectChanges()
        }

        // Two updates occur. Although there is no practical difference as no "await" occurs between the assignments,
        // we need to dequeue twice to observe the change.
        let nextOptionalState = await states.next()
        let nextState = try XCTUnwrap(nextOptionalState)
        XCTAssertEqual(nextState.projectPanelState, .moreDataNeeded)
        XCTAssertEqual(nextState.modelPanelState, .loading)

        let thirdOptionalState = await states.next()
        let thirdState = try XCTUnwrap(thirdOptionalState)
        XCTAssertEqual(thirdState.projectPanelState, .moreDataNeeded)
        XCTAssertEqual(thirdState.modelPanelState, .noModelAvailable)

        // Cancel task when done.
        monitorTask.cancel()
    }

    func testTrainingProgressOccurs() async throws {
        var states = trainingViewModel.$trainingViewState.values.makeAsyncIterator()

        await projectModelInfoRepository.updateProjectModelInfo(ProjectModelInfo(
                version: "1.1",
                labels: [ .fakeAppleLabel, .fakeBananaLabel ],
                sampleIDsByLabelUUID: [
                    .fakeAppleLabelUUID: [
                        .fakeApple1SampleUUID,
                        .fakeApple2SampleUUID,
                        .fakeApple3SampleUUID
                    ],
                    .fakeBananaLabelUUID: [
                        .fakeBanana1SampleUUID,
                        .fakeBanana2SampleUUID,
                        .fakeBanana3SampleUUID,
                    ]
                ],
                testSampleIDsByLabelUUID: [:]))

        // Ignore the initial loading state, which is tested above.
        _ = await states.next()

        // Refresh training data, yielding an evaluation of project model info.
        let monitorTask = Task {
            await trainingViewModel.monitorProjectChanges()
        }

        // Two updates occur. Although there is no practical difference as no "await" occurs between the assignments,
        // we need to dequeue twice to observe the change.
        let nextOptionalState = await states.next()
        let nextState = try XCTUnwrap(nextOptionalState)
        XCTAssertEqual(nextState.projectPanelState, .readyToTrain(trainableLabelCount: 2, progressState: nil))
        XCTAssertEqual(nextState.modelPanelState, .loading)

        let thirdOptionalState = await states.next()
        let thirdState = try XCTUnwrap(thirdOptionalState)
        XCTAssertEqual(thirdState.projectPanelState, .readyToTrain(trainableLabelCount: 2, progressState: nil))
        XCTAssertEqual(thirdState.modelPanelState, .noModelAvailable)

        // Simulate "start training" button press.
        trainingViewModel.startTraining()

        let fourthOptionalState = await states.next()
        let fourthState = try XCTUnwrap(fourthOptionalState)
        XCTAssertEqual(fourthState.modelPanelState, .training)
        XCTAssertFalse(fourthState.isTraining)

        let fifthOptionalState = await states.next()
        let fifthState = try XCTUnwrap(fifthOptionalState)
        XCTAssertTrue(fifthState.isTraining)

        let sixthOptionalState = await states.next()
        let sixthState = try XCTUnwrap(sixthOptionalState)
        XCTAssertEqual(sixthState.projectPanelState, .readyToTrain(trainableLabelCount: 2, progressState: .init(progress: 0.3, subtitle: "Copying files…")))

        // Cancel task when done.
        monitorTask.cancel()
    }
}

