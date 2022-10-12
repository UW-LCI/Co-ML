// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

@MainActor
final class ProjectModelInfoRepositoryTests: XCTestCase {

    var databaseStorageService: DatabaseStorageService!

    override func setUp() {
        super.setUp()
        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())
    }

    override func tearDown() {
        databaseStorageService = nil
        super.tearDown()
    }

    func testProjectModelInfoRepositoryFetchFailsWithNoProject() async throws {
        let projectID = ProjectID()
        let projectModelInfoRepository = ProjectModelInfoRepositoryImpl(
            projectID: projectID,
            databaseStorageService: databaseStorageService)

        do {
            let info = try await projectModelInfoRepository.fetchProjectModelInfo()
            XCTFail("Unexpectedly got info \(info)")

        } catch {
            if case let DatabaseStorageServiceError.projectNotFound(errorProjectID) = error {
                XCTAssertEqual(errorProjectID, projectID)
            } else {
                XCTFail("Unexpected error \(error)")
            }
        }
    }

    func testDefaultProjectModelInfoRepositoryFetchReturnsEmptySampleArrays() async throws {
        // Add a project to the database.
        let projectID = ProjectID()
        let projectCreatedAt = Date()
        let project = Project(
            id: projectID,
            title: "Test Project",
            createdAt: projectCreatedAt)
        try await databaseStorageService.create(project: project)

        // Set up the project model info repository.
        let projectModelInfoRepository = ProjectModelInfoRepositoryImpl(
            projectID: projectID,
            databaseStorageService: databaseStorageService)

        // Verify it returns the expected model info.
        let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
        XCTAssertEqual(projectModelInfo.labels.count, 2)
        for label in projectModelInfo.labels {
            let labelUUID = label.id.id
            guard let sampleUUIDs = projectModelInfo.sampleIDsByLabelUUID[labelUUID] else {
                XCTFail("Unexpectedly no model info for \(labelUUID)")
                continue
            }
            XCTAssertTrue(sampleUUIDs.isEmpty)
        }
    }

    func testProjectModelInfoRepositoryFetchReturnsInsertedSampleIDs() async throws {
        // Add a project to the database.
        let projectID = ProjectID()
        let projectCreatedAt = Date()
        let project = Project(
            id: projectID,
            title: "Test Project",
            createdAt: projectCreatedAt)
        try await databaseStorageService.create(project: project)

        // Set up the project model info repository.
        let projectModelInfoRepository = ProjectModelInfoRepositoryImpl(
            projectID: projectID,
            databaseStorageService: databaseStorageService)

        // Use the initial model info to insert some samples into the first label.
        var projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
        var firstLabel = try XCTUnwrap(projectModelInfo.labels.first)
        let labeledImage = LabeledImage(
            image: UIImage(systemName: "box.truck")!,
            labelID: firstLabel.id)
        try await databaseStorageService.add(labeledImage: labeledImage)

        // Then fetch model info again, and verify the inserted label ID is present.
        projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()
        firstLabel = try XCTUnwrap(projectModelInfo.labels.first)
        let labelUUID = firstLabel.id.id
        guard let sampleUUIDs = projectModelInfo.sampleIDsByLabelUUID[labelUUID] else {
            XCTFail("Unexpectedly no model info for \(labelUUID)")
            return
        }
        XCTAssertFalse(sampleUUIDs.isEmpty)
        let firstSampleUUID = try XCTUnwrap(sampleUUIDs.first)
        XCTAssertEqual(firstSampleUUID, labeledImage.sampleID)
    }
}
