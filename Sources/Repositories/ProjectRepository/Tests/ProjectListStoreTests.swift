// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class ProjectListStoreTests: XCTestCase {
    private var clarendonID: UUID {
        UUID(uuidString: "19517F87-DCAB-4C6D-976A-9A60BCB0D74B")!
    }

    private var manchesterID: UUID {
        UUID(uuidString: "B59A7CA7-224C-44E7-AE7C-02E9B1719FEB")!
    }

    var databaseStorageService: DatabaseStorageService!
    var projectListRepository: ProjectsListRepository!

    override func setUp() async throws {
        try await super.setUp()

        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())
        try await databaseStorageService.create(project: Project(id: clarendonID, title: "Clarendon", createdAt: Date()))
        try await databaseStorageService.create(project: Project(id: manchesterID, title: "Manchester", createdAt: Date()))

        projectListRepository = ProjectListStore(databaseStorageService: databaseStorageService)
    }

    func testShouldHaveTwoViewModelsForTwoProjects() async throws {
        let viewModels = try await projectListRepository.load()
        XCTAssertEqual(viewModels.count, 2)
    }

    func testLoadingWithMoreThan8ThumbnailsShouldReturnOnly8() async throws {
        let viewModels = try await projectListRepository.load()

        let manchester = viewModels.first(where: { $0.project.id == manchesterID })

        XCTAssertTrue((manchester?.thumbnails ?? []).count == 8)
    }

    func testIfThereAreLessThan8ThumbnailsWeShouldStillHave8() async throws {
        let viewModels = try await projectListRepository.load()
        let clarendon = viewModels.first(where: { $0.project.id == clarendonID })

        XCTAssertTrue(
            (clarendon?.thumbnails ?? []).count == 8,
            "We fill missing thumbnails with placeholders."
        )
    }

    func testTotalSampleCount() async throws {
        // Add some samples to the Clarendon project.
        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: clarendonID)
        let firstDefaultLabelID = try XCTUnwrap(projectModelInfo.labels.first?.id)
        for _ in 0..<3 {
            let labeledImage = LabeledImage(image: UIImage(systemName: "box.truck")!, labelID: firstDefaultLabelID)
            try await databaseStorageService.add(labeledImage: labeledImage)
        }
        // Then verify they are reflected in the sample count.
        let viewModels = try await projectListRepository.load()
        let clarendon = viewModels.first(where: { $0.project.id == clarendonID })
        XCTAssertEqual(clarendon?.totalSampleCount, 3)
    }

    func testDeleteShouldRemoveProject() async throws {
        try await projectListRepository.delete(projectIDs: [ manchesterID ], isOnline: true)
        let projects = try await projectListRepository.load()

        if let _ = projects.first(where: { $0.id == manchesterID }) {
            XCTFail("Manchester should have been deleted.")
        }
    }

    func testCreateShouldAddANewProject() async throws {
        let title = "Rio Minho Mullets"
        try await projectListRepository.create(
            project: Project(id: UUID(), title: title, createdAt: Date())
        )
        let projects = try await projectListRepository.load()
        if projects.first(where: { $0.project.title == title }) == nil {
            XCTFail("There should be a project with the new title.")
        }
    }
}
