// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import UniformTypeIdentifiers
@testable import CoMLApp

final class TrainingDataWriterTests: XCTestCase {
    private let appTempDirectoryURL = URL.temporaryDirectory
    private let groupOneName = "one"
    private let groupTwoName = "two"

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(
            at: appTempDirectoryURL.appendingPathComponent(groupOneName)
        )
        try FileManager.default.removeItem(
            at: appTempDirectoryURL.appendingPathComponent(groupTwoName)
        )
        try super.tearDownWithError()
    }

    func testWriteShouldWriteToURLForAllGroups() throws {
        let groupOneSample = AnnotatedSample(
            annotation: LabelAnnotation(labelID: .fakeAppleLabelID, label: "Apples"),
            sampleType: .jpeg,
            sampleData: Data(groupOneName.utf8),
            creationDate: Date()
        )
        let groupOneSampleID = groupOneSample.id
        let groupOne = SingleLabelTrainingGroup(annotation: groupOneName, sampleIDs: [
            groupOneSampleID
        ])

        let groupTwoSample = AnnotatedSample(
            annotation: LabelAnnotation(labelID: .fakeAppleLabelID, label: "Apples"),
            sampleType: .jpeg,
            sampleData: Data(groupTwoName.utf8),
            creationDate: Date()
        )
        let groupTwoSampleID = groupTwoSample.id
        let groupTwo = SingleLabelTrainingGroup(annotation: groupTwoName, sampleIDs: [
            groupTwoSampleID
        ])

        let dataset = SingleLabelTrainingDataset(
            mediaType: .jpeg,
            sampleGroups: [groupOne, groupTwo]
        )

        let databaseStorageService = DatabaseStorageServiceFake(
            projects: [],
            samplesByLabelID: [
                .fakeAppleLabelID: [ groupOneSample ],
                .fakeBananaLabelID: [ groupTwoSample ]
            ]
        )

        try TrainingDataWriter.write(dataset: dataset,
                                     to: appTempDirectoryURL,
                                     databaseStorageService: databaseStorageService)

        let groupOneURL = appTempDirectoryURL
            .appendingPathComponent(groupOneName)
            .appendingPathComponent("\(groupOneName)-\(groupOneSampleID).jpeg")

        XCTAssertTrue(try String(contentsOf: groupOneURL, encoding: .utf8) == "one")

        let groupTwoURL = appTempDirectoryURL
            .appendingPathComponent(groupTwoName)
            .appendingPathComponent("\(groupTwoName)-\(groupTwoSampleID).jpeg")
        XCTAssertTrue(try String(contentsOf: groupTwoURL, encoding: .utf8) == "two")
    }
}
