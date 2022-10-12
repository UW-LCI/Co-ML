// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit
import XCTest
@testable import CoMLApp

@MainActor
final class ClassificationCameraViewModelTests: XCTestCase {

    let projectID = ProjectID(uuidString: "8806551b-4f3f-44b4-ba83-0a63ece9928d")!
    var validationRepository: ValidationRepository!
    var sut: ClassificationCameraViewModel!

    override func setUp() {
        super.setUp()

        let projectLabels = [
            LabelAnnotation(label: "apple", projectID: projectID),
            LabelAnnotation(label: "banana", projectID: projectID)
        ]

        validationRepository = ValidationRepositoryFake(projectID: projectID, labels: projectLabels)

        let imageStreamer = ClassificationImageStreamer(
            projectID: projectID,
            validationRepository: validationRepository,
            photoSizer: PhotoSizerImpl())

        let projectModelInfoRepository = ProjectModelInfoRepositoryFake(
            projectID: projectID,
            projectModelInfo: ProjectModelInfo(
                version: "1.1",
                labels: projectLabels,
                sampleIDsByLabelUUID: [:],
                testSampleIDsByLabelUUID: [:]
            )
        )

        sut = ClassificationCameraViewModel(
            projectID: projectID,
            classificationImageStreamer: imageStreamer,
            projectModelInfoRepository: projectModelInfoRepository,
            imageRepository: .fake(projectID: projectID),
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: projectID)
        )
    }

    override func tearDown() {
        sut = nil
        validationRepository = nil
        super.tearDown()
    }

    func testInitialStateIsEmpty() async {
        XCTAssertTrue(sut.observations.isEmpty)
        XCTAssertNil(sut.topPredictionResult)
        XCTAssertNil(sut.imageCapturedByUser)
    }

    func testSendingImagesThroughImageStreamerResultsInObservations() async throws {
        try await sut.setupAndStreamFirstImage()
        XCTAssertEqual(sut.observations.count, 1)
        let firstObservation = try XCTUnwrap(sut.observations.first)

        XCTAssertNotNil(firstObservation.annotation)
        XCTAssertGreaterThan(firstObservation.confidence, 0.0)
        XCTAssertNotNil(sut.imageCapturedByUser)
    }

    func testClearResults() async throws {
        try await sut.setupAndStreamFirstImage()
        XCTAssertEqual(sut.observations.count, 1)
        XCTAssertNotNil(sut.imageCapturedByUser)

        sut.clearResults()
        // clearResults uses a withAnimation block, so we need to wait
        try await Task.sleep(milliseconds: 100)

        XCTAssertTrue(sut.observations.isEmpty)
        XCTAssertNil(sut.imageCapturedByUser)
    }

    func testProcessingLiveClassificationsFromCameraStartsOutEmpty() async throws {
        XCTAssertTrue(sut.liveStreamedObservations.isEmpty)
    }

    func testProcessingLiveClassificationsFromCameraUpdatesUI() async throws {
        let settings = CameraSettings(saveDestination: .training, viewMode: .classificationMode)
        let projectModelInfoRepository = ProjectModelInfoRepositoryFake(projectID: projectID)
        let cameraViewModel = CameraViewModel(
            projectID: projectID,
            cameraSettings: settings,
            projectModelInfoRepository: projectModelInfoRepository,
            imageFetchRepository: ImageFetchRepositoryFake(),
            imageRepository: ImageRepositoryFake(projectID: projectID),
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: projectID))

        let sut = ClassificationCameraViewModel(
            projectID: projectID,
            classificationImageStreamer: cameraViewModel.classificationImageStreamer,
            projectModelInfoRepository: projectModelInfoRepository,
            imageRepository: ImageRepositoryFake(projectID: projectID),
            validationRepository: validationRepository,
            modelStorageService: .fake(projectID: projectID)
        )

        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await sut.processClassification()
            }
            let cancel = group.cancelAll
            group.addTask { @MainActor in
                try await Task.sleep(milliseconds: 100)
                await cameraViewModel.classificationImageStreamer.sendImage(UIImage())
                try await Task.sleep(milliseconds: 500)
                XCTAssertEqual(sut.liveStreamedObservations.count, 1)

                // If we send a second image through, the count should still be one (we replace, not append)
                await cameraViewModel.classificationImageStreamer.sendImage(UIImage())
                try await Task.sleep(milliseconds: 500)
                XCTAssertEqual(sut.liveStreamedObservations.count, 1)
                cancel()
            }
        }
    }
}

private extension ClassificationCameraViewModel {
    func setupAndStreamFirstImage() async throws {
        let sut = self
        Task {
            // this may run forever
            await sut.processClassification()
        }
        await sut.processPhotoTaken(image: UIImage())
        try await Task.sleep(milliseconds: 100)
    }
}
