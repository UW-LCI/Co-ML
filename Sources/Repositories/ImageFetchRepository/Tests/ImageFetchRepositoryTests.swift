// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

@MainActor
final class ImageFetchRepositoryTests: XCTestCase {

    func testImageFetchRepositoryThrowsWithNoSample() async throws {
        let databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())
        let imageFetchRepository = ImageFetchRepositoryImpl(databaseStorageService: databaseStorageService)
        do {
            let unknownProjectID = ProjectID()
            let unknownLabelID = LabelID(id: UUID(), projectID: unknownProjectID)
            let labeledImageID = LabeledImageID(labelID: unknownLabelID)
            do {
                _ = try await imageFetchRepository.fetchImage(sampleUUID: labeledImageID.id)
            } catch {
                if case let DatabaseStorageServiceError.sampleNotFound(missingSampleID) = error {
                    XCTAssertEqual(missingSampleID, labeledImageID.id)
                    return
                }
                XCTFail("Unexpected error: \(error)")
            }
            XCTFail("Expected to throw.")
        }
    }

    func testImageFetchRepositoryYieldsImageFromDatabase() async throws {
        let databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())
        let projectID = ProjectID()
        let newProject = Project(id: projectID, title: "Test Project", createdAt: Date())
        try await databaseStorageService.create(project: newProject)

        // Use the project model info to get the first label, to which we will insert an image.
        let projectModelInfo = try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
        let firstLabel = try XCTUnwrap(projectModelInfo.labels.first)

        // Insert an image.
        let newImage = LabeledImage(image: UIImage(systemName: "box.truck")!, labelID: firstLabel.id)
        try await databaseStorageService.add(labeledImage: newImage)

        // Verify that image can be fetched.
        let imageFetchRepository = ImageFetchRepositoryImpl(databaseStorageService: databaseStorageService)
        let fetchedImage = try await imageFetchRepository.fetchImage(sampleUUID: newImage.sampleID)
        XCTAssertNotNil(fetchedImage)
    }
}
