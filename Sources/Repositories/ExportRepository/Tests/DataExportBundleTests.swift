// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
import UniformTypeIdentifiers
@testable import CoMLApp

@MainActor
final class DataExportBundleTests: XCTestCase {
    static let fruitProjectID = ProjectID.fakeProjectID

    override func tearDown() {
        super.tearDown()
        do {
            let projectID = ProjectID.fakeProjectID
            try DataExportBundle.cleanupExportData(projectID: projectID)
        } catch let error {
            print("Error: Failed to delete testing export data: \(error)")
        }
    }

    static let apple1 = AnnotatedSample(
        annotation: .fakeAppleLabel,
        sampleType: .jpeg,
        sampleData: UIImage(systemName: "box.truck")!.jpegData(compressionQuality: 1.0)!,
        creationDate: .date1
    )

    static let apple2 = AnnotatedSample(
        annotation: .fakeAppleLabel,
        sampleType: .jpeg,
        sampleData: UIImage(systemName: "box.truck")!.jpegData(compressionQuality: 1.0)!,
        creationDate: .date2
    )

    static let banana1 = AnnotatedSample(
        annotation: .fakeBananaLabel,
        sampleType: .jpeg,
        sampleData: UIImage(systemName: "pencil.circle")!.jpegData(compressionQuality: 1.0)!,
        creationDate: .date5
    )

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

    static func setupTestProjectDatabase() async throws -> DatabaseStorageService {
        let projectID = ProjectID.fakeProjectID
        let databaseStorageService = DatabaseStorageServiceFake(
            projectsByID: [
                projectID: Project(id: projectID, title: "Fruits", createdAt: Date()),
            ],
            samplesByLabelID: [
                .fakeAppleLabelID: [ .fakeApple1Sample, .fakeApple2Sample ],
                .fakeBananaLabelID: [ .fakeBanana1Sample ]
            ],
            labels: labelAnnotations
        )

        let labels = try await databaseStorageService.fetchLabels(projectID: projectID)
        XCTAssertEqual(labels.count, 3)

        return databaseStorageService
    }

    func testDataExportProducesValidURL() async throws {
        let projectID = Self.fruitProjectID
        let databaseStorageService = try await Self.setupTestProjectDatabase()
        let bundle = DataExportBundle(projectID: projectID, databaseStorageService: databaseStorageService)
        let url = try await bundle.prepareExport()

        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
        XCTAssertFalse(contents.isEmpty)
    }

    func testDataExportProducesLabelFolders() async throws {
        let projectID = Self.fruitProjectID
        let databaseStorageService = try await Self.setupTestProjectDatabase()
        let bundle = DataExportBundle(projectID: projectID, databaseStorageService: databaseStorageService)
        let url = try await bundle.prepareExport()
        let trainURL = url.appendingPathComponent(DataType.training.directoryName)

        // look for Bananas and Apples folder, no Carrots folder since that label has no data
        let contents = try FileManager.default.contentsOfDirectory(at: trainURL, includingPropertiesForKeys: [])
        XCTAssertEqual(contents.count, 3)
        let folderNames = contents.map(\.lastPathComponent)
        XCTAssertTrue(folderNames.contains("Apple"))
        XCTAssertTrue(folderNames.contains("Banana"))
        XCTAssertTrue(folderNames.contains("Carrot"))
    }

    func testDataExportProducesTestTrainFolders() async throws {
        let projectID = Self.fruitProjectID
        let databaseStorageService = try await Self.setupTestProjectDatabase()
        let bundle = DataExportBundle(projectID: projectID, databaseStorageService: databaseStorageService)
        let url = try await bundle.prepareExport()

        // look for test and train folders
        let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
        XCTAssertEqual(contents.count, DataType.allCases.count)
        XCTAssertTrue(contents.contains(where: { $0.lastPathComponent == "test" }))
        XCTAssertTrue(contents.contains(where: { $0.lastPathComponent == "train" }))
    }

    func testDataExportProducesImages() async throws {
        let projectID = Self.fruitProjectID
        let databaseStorageService = try await Self.setupTestProjectDatabase()
        let bundle = DataExportBundle(projectID: projectID, databaseStorageService: databaseStorageService)
        let url = try await bundle.prepareExport()

        // look for test and train folders
        let test = url.appendingPathComponent("test", conformingTo: .directory)
        let train = url.appendingPathComponent("train", conformingTo: .directory)

        // look for Apple test folder
        let apples_test = test.appendingPathComponent("Apple", conformingTo: .directory)
        let test_contents = try FileManager.default.contentsOfDirectory(at: apples_test, includingPropertiesForKeys: [])
        XCTAssertEqual(test_contents.count, 0)

        // look for Apple train folder
        let apples_train = train.appendingPathComponent("Apple", conformingTo: .directory)
        let train_contents = try FileManager.default.contentsOfDirectory(at: apples_train, includingPropertiesForKeys: [])
        XCTAssertEqual(train_contents.count, 2)
    }

    func testDataExportCleanup() async throws {
        let projectID = Self.fruitProjectID
        let databaseStorageService = try await Self.setupTestProjectDatabase()
        let bundle = DataExportBundle(projectID: projectID, databaseStorageService: databaseStorageService)
        let url = try await bundle.prepareExport()

        let projectURL = url.deletingLastPathComponent()
        print("Project URL is", projectURL)

        // expect exports are here
        let before_contents = try FileManager.default.contentsOfDirectory(atPath: projectURL.path())
        XCTAssertFalse(before_contents.isEmpty)

        try DataExportBundle.cleanupExportData(projectID: projectID)
        let after_contents = FileManager.default.fileExists(atPath: projectURL.path())
        XCTAssertFalse(after_contents)
    }
}

