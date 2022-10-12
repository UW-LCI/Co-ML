// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class ProjectModelInfoTests: XCTestCase {

    static let trainingService = TrainingServiceFake()

    func testEmptyProjectModelInfoIsNotReadyToTrain() {
        let projectModelInfo = ProjectModelInfo(
            version: "1.1",
            labels: [],
            sampleIDsByLabelUUID: [:],
            testSampleIDsByLabelUUID: [:])
        XCTAssertFalse(Self.trainingService.hasEnoughDataToTrain(projectModelInfo))
        XCTAssertEqual(projectModelInfo.sampleCount, 0)
    }

    func testProjectModelInfoWithEnoughDataToTrain() {
        let labels: [LabelAnnotation] = [ .fakeAppleLabel, .fakeBananaLabel, .fakeCarrotLabel ]
        let appleIDs: [LabeledImageID] = [ .fakeApple1id, .fakeApple2id, .fakeApple3id ]
        let bananaIDs: [LabeledImageID] = [ .fakeBanana1id, .fakeBanana2id, .fakeBanana3id ]

        let projectModelInfo = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: appleIDs.map(\.id),
                LabelAnnotation.fakeBananaLabel.id.id: bananaIDs.map(\.id),
            ],
            testSampleIDsByLabelUUID: [:])

        XCTAssertTrue(Self.trainingService.hasEnoughDataToTrain(projectModelInfo))
        XCTAssertEqual(projectModelInfo.sampleCount, 6)
    }

    func testProjectModelInfoComparisonDetectsAddedLabel() {
        let projectModelInfo1 = ProjectModelInfo(
            version: "1.1",
            labels: [],
            sampleIDsByLabelUUID: [:],
            testSampleIDsByLabelUUID: [:])

        let labels: [LabelAnnotation] = [ .fakeAppleLabel ]
        let appleIDs: [LabeledImageID] = [ .fakeApple1id ]

        let projectModelInfo2 = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: appleIDs.map(\.id)
            ],
            testSampleIDsByLabelUUID: [:])

        let changes = projectModelInfo2.changes(since: projectModelInfo1)

        XCTAssertEqual(changes.count, 1)
        if case let .labelAdded(labelString) = changes.first {
            XCTAssertEqual(labelString, LabelAnnotation.fakeAppleLabel.labelString)
        } else {
            XCTFail("Unexpected change")
        }
    }

    func testProjectModelInfoComparisonDetectsDeletedLabel() {
        let labels: [LabelAnnotation] = [ .fakeAppleLabel ]
        let appleIDs: [LabeledImageID] = [ .fakeApple1id ]
        let projectModelInfo1 = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: appleIDs.map(\.id)
            ],
            testSampleIDsByLabelUUID: [:])

        let projectModelInfo2 = ProjectModelInfo(
            version: "1.1",
            labels: [],
            sampleIDsByLabelUUID: [:],
            testSampleIDsByLabelUUID: [:])

        let changes = projectModelInfo2.changes(since: projectModelInfo1)

        XCTAssertEqual(changes.count, 1)
        if case let .labelDeleted(labelString) = changes.first {
            XCTAssertEqual(labelString, LabelAnnotation.fakeAppleLabel.labelString)
        } else {
            XCTFail("Unexpected change")
        }
    }

    func testProjectModelInfoComparisonDetectsRenamedLabel() {
        let originalLabel = LabelAnnotation.fakeAppleLabel
        let updatedLabel = LabelAnnotation(existingAnnotation: originalLabel, updatedString: "Oranges")

        let projectModelInfo1 = ProjectModelInfo(
            version: "1.1",
            labels: [ originalLabel ],
            sampleIDsByLabelUUID: [:],
            testSampleIDsByLabelUUID: [:])

        let projectModelInfo2 = ProjectModelInfo(
            version: "1.1",
            labels: [ updatedLabel ],
            sampleIDsByLabelUUID: [:],
            testSampleIDsByLabelUUID: [:])

        let changes = projectModelInfo2.changes(since: projectModelInfo1)

        XCTAssertEqual(changes.count, 1)
        if case let .labelRenamed(oldLabelString, newLabelString) = changes.first {
            XCTAssertEqual(oldLabelString, originalLabel.labelString)
            XCTAssertEqual(newLabelString, updatedLabel.labelString)
        } else {
            XCTFail("Unexpected change")
        }
    }

    func testProjectModelInfoComparisonDetectsReplacedSample() {
        let labels: [LabelAnnotation] = [ .fakeAppleLabel ]

        let projectModelInfo1 = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: [
                    LabeledImageID.fakeApple1id.id
                ]
            ],
            testSampleIDsByLabelUUID: [:])

        let projectModelInfo2 = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: [
                    LabeledImageID.fakeApple2id.id // This is what changed.
                ]
            ],
            testSampleIDsByLabelUUID: [:])

        let changes = projectModelInfo2.changes(since: projectModelInfo1)

        XCTAssertEqual(changes.count, 1)
        if case let .samplesChanged(addedSampleCount, removedSampleCount, labelString) = changes.first {
            XCTAssertEqual(addedSampleCount, 1)
            XCTAssertEqual(removedSampleCount, 1)
            XCTAssertEqual(labelString, LabelAnnotation.fakeAppleLabel.labelString)
        } else {
            XCTFail("Unexpected change")
        }
    }

    func testEqualProjectModelInfosReturnNoChanges() {
        let labels: [LabelAnnotation] = [ .fakeAppleLabel, .fakeBananaLabel, .fakeCarrotLabel ]
        let appleIDs: [LabeledImageID] = [ .fakeApple1id, .fakeApple2id, .fakeApple3id ]
        let bananaIDs: [LabeledImageID] = [ .fakeBanana1id, .fakeBanana2id ]
        let carrotIDs: [LabeledImageID] = [ .fakeCarrot1id ]

        let projectModelInfo1 = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: appleIDs.map(\.id),
                LabelAnnotation.fakeBananaLabel.id.id: bananaIDs.map(\.id),
                LabelAnnotation.fakeCarrotLabel.id.id: carrotIDs.map(\.id)
            ],
            testSampleIDsByLabelUUID: [:])

        let projectModelInfo2 = ProjectModelInfo(
            version: "1.1",
            labels: labels,
            sampleIDsByLabelUUID: [
                LabelAnnotation.fakeAppleLabel.id.id: appleIDs.map(\.id),
                LabelAnnotation.fakeBananaLabel.id.id: bananaIDs.map(\.id),
                LabelAnnotation.fakeCarrotLabel.id.id: carrotIDs.map(\.id)
            ],
            testSampleIDsByLabelUUID: [:])

        let changes = projectModelInfo2.changes(since: projectModelInfo1)
        XCTAssertEqual(changes.count, 0)
    }
}
