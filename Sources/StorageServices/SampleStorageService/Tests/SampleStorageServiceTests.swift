// Copyright 2026 Apple Inc. All rights reserved.

@testable import CoMLApp
import UIKit
import XCTest
@testable import CoMLApp

final class SampleStorageServiceTests: XCTestCase {
    private let projectID = UUID(uuidString: "7a2ee175-b3f2-4c69-8f7a-5d221c467938")!

    var coreDataStack: CoreDataStack!
    var databaseStorageService: DatabaseStorageService!
    var sampleStorageService: SampleStorageService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStackFake()
        databaseStorageService = CoreDataDatabaseStorageService(coreDataStack: coreDataStack)
        sampleStorageService = SampleStorageServiceImpl(databaseStorageService: databaseStorageService)
    }

    override func tearDown() {
        sampleStorageService = nil
        databaseStorageService = nil
        coreDataStack = nil
        super.tearDown()
    }

    func testLabelCannotBeSavedIfNoProjectExists() async throws {
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        do {
            try await sampleStorageService.add(label: truckLabel)
        } catch let e as DatabaseStorageServiceError {
            guard case let .projectNotFound(notFoundProjectID) = e else {
                XCTFail("Unexpected error \(e)")
                return
            }
            XCTAssertEqual(notFoundProjectID, projectID)
            return
        }
        XCTFail("Expected error not thrown")
    }

    func testLabelSavedInSampleStorageServiceCanBeFetched() async throws {
        try await databaseStorageService.create(project: Project(id: projectID, title: "Trucks Project", createdAt: Date()))
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        try await sampleStorageService.add(label: truckLabel)

        let labels = try await sampleStorageService.fetchLabels(projectID: projectID)
        XCTAssertEqual(labels.count, 3)
        XCTAssertEqual(labels[2], truckLabel)
    }

    func testImageCanBeAddedToLabelInProject() async throws {
        try await databaseStorageService.create(project: Project(id: projectID, title: "Trucks Project", createdAt: Date()))
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        try await sampleStorageService.add(label: truckLabel)
        let truckImage = LabeledImage(image: UIImage(systemName: "box.truck")!, labelID: truckLabel.id)
        try await sampleStorageService.add(labeledImage: truckImage)

        let images = try await sampleStorageService.fetchSamples(labelID: truckLabel.id, dataType: .training)
        XCTAssertEqual(images.count, 1)
    }
}
