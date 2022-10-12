// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class LabelDetailRepositoryTests: XCTestCase {

    var projectModelInfoRepository: ProjectModelInfoRepository!
    static let applesLabel = LabelAnnotation.fakeAppleLabel
    static let bananasLabel = LabelAnnotation.fakeBananaLabel

    override func setUp() {
        super.setUp()

        let labels: [LabelAnnotation] = [ Self.applesLabel, Self.bananasLabel ]

        let appleTrainingImageIDs: [LabeledImageID] = [ .fakeApple1id, .fakeApple2id, .fakeApple3id ]
        let appleTestingImageIDs: [LabeledImageID] = [ .fakeApple4id ]

        let projectModelInfo = ProjectModelInfo(version: "1.1",
                                                labels: labels,
                                                sampleIDsByLabelUUID: [
                                                    Self.applesLabel.id.id: appleTrainingImageIDs.map { $0.sampleID },
                                                    Self.bananasLabel.id.id: []
                                                ],
                                                testSampleIDsByLabelUUID: [
                                                    Self.applesLabel.id.id: appleTestingImageIDs.map { $0.sampleID },
                                                    Self.bananasLabel.id.id: []
                                                ])

        projectModelInfoRepository = ProjectModelInfoRepositoryFake(
            projectID: .fakeProjectID,
            projectModelInfo: projectModelInfo
        )
    }

    func testEmptyFetchesDoNotThrow() async throws {
        let labelUnderTest = Self.bananasLabel
        let trainingRepository = LabelDetailRepositoryImpl(labelID: labelUnderTest.id,
                                                           dataType: .training,
                                                           projectModelInfoRepository: projectModelInfoRepository)

        let trainingImageIDs = try await trainingRepository.fetchImageIDs()
        XCTAssertTrue(trainingImageIDs.isEmpty)

        let testingRepository = LabelDetailRepositoryImpl(labelID: labelUnderTest.id,
                                                          dataType: .testing,
                                                          projectModelInfoRepository: projectModelInfoRepository)
        let testingImageIDs = try await testingRepository.fetchImageIDs()
        XCTAssertTrue(testingImageIDs.isEmpty)
    }

    func testMissingFetchThrows() async throws {
        let labelUnderTest = LabelAnnotation.fakeCarrotLabel
        let trainingRepository = LabelDetailRepositoryImpl(labelID: labelUnderTest.id,
                                                           dataType: .training,
                                                           projectModelInfoRepository: projectModelInfoRepository)

        do {
            _ = try await trainingRepository.fetchImageIDs()
            XCTFail("Image fetch is expected to fail when the project has no such label")
        } catch {
            // Success
        }
    }

    func testFetchFiltersAsExpected() async throws {
        let labelUnderTest = Self.applesLabel
        let trainingRepository = LabelDetailRepositoryImpl(labelID: labelUnderTest.id,
                                                           dataType: .training,
                                                           projectModelInfoRepository: projectModelInfoRepository)

        let trainingImageIDs = try await trainingRepository.fetchImageIDs()
        XCTAssertEqual(trainingImageIDs, [ .fakeApple1id, .fakeApple2id, .fakeApple3id ])

        let testingRepository = LabelDetailRepositoryImpl(labelID: labelUnderTest.id,
                                                          dataType: .testing,
                                                          projectModelInfoRepository: projectModelInfoRepository)
        let testingImageIDs = try await testingRepository.fetchImageIDs()
        XCTAssertEqual(testingImageIDs, [ .fakeApple4id ])
    }
}
