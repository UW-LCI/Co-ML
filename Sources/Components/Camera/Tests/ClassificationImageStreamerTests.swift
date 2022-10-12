// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import XCTest
@testable import CoMLApp

final class ClassificationImageStreamerTests: XCTestCase {

    func testOneStreamedImageIsReceivedSuccessfully() async throws {
        let sut = await ClassificationImageStreamer(projectID: validationRepository.projectID, validationRepository: validationRepository, photoSizer: PhotoSizerImpl())

        Task {
            try await Task.sleep(milliseconds: 100)
            await sut.sendImage(UIImage())
        }

        var imagesReceived = 0
        for await _ in await sut.liveObservationsFromCamera() {
            imagesReceived += 1
            if imagesReceived == 1 {
                break
            }
        }
        XCTAssertEqual(imagesReceived, 1)
    }

    func testTwentyFramesResultsInOnlyOneStreamedImage() async throws {
        let sut = await ClassificationImageStreamer(projectID: validationRepository.projectID, validationRepository: validationRepository, photoSizer: PhotoSizerImpl())

        Task {
            try await Task.sleep(milliseconds: 100)
            for _ in 1...ClassificationImageStreamer.processingThreshold {
                await sut.sendImage(UIImage())
            }
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                var imagesReceived = 0

                for await _ in await sut.liveObservationsFromCamera() {
                    imagesReceived += 1
                    if imagesReceived > 1 {
                        XCTFail("Too many images received")
                        break
                    }
                }
                XCTAssertEqual(imagesReceived, 1)
            }

            let cancel = group.cancelAll
            group.addTask {
                try? await Task.sleep(seconds: 1)
                cancel()
            }
        }

    }

    func test41FramesResultsInThreeStreamedImages() async throws {
        let sut = await ClassificationImageStreamer(projectID: validationRepository.projectID, validationRepository: validationRepository, photoSizer: PhotoSizerImpl())

        Task {
            try await Task.sleep(milliseconds: 100)
            for _ in 1...41 {
                await sut.sendImage(UIImage())
            }
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                var imagesReceived = 0

                for await _ in await sut.liveObservationsFromCamera() {
                    imagesReceived += 1
                    if imagesReceived > 3 {
                        XCTFail("Too many images received")
                        break
                    }
                }
                XCTAssertEqual(imagesReceived, 3)
            }

            let cancel = group.cancelAll
            group.addTask {
                try? await Task.sleep(seconds: 2)
                cancel()
            }
        }
    }

    private var validationRepository: ValidationRepositoryFake {
        let projectID = ProjectID(uuidString: "a5932c86-acdd-4f42-bac6-dafc7146cf11")!
        let validationRepository = ValidationRepositoryFake(projectID: projectID,
                                                      labels: [LabelAnnotation(labelID: .init(id: UUID(), projectID: projectID), label: "cat"),
                                                               LabelAnnotation(labelID: .init(id: UUID(), projectID: projectID), label: "dog")])
        return validationRepository
    }
}
