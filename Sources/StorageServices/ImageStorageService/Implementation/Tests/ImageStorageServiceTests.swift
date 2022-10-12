// Copyright 2026 Apple Inc. All rights reserved.

@testable import CoMLApp
import UIKit
import XCTest
@testable import CoMLApp

final class ImageStorageServiceTests: XCTestCase {
    enum Labels {
        static let truck = "Truck"
        static let sun = "Sun"
    }

    private let projectID = UUID(uuidString: "f871a6c1-c263-42dd-9d1b-af0a2bfbfc8c")!
    private let anotherProjectID = UUID(uuidString: "3dcde364-8503-4b06-8add-388268172bb2")!
    private var imageStorageService: ImageStorageService!

    override func setUp() {
        super.setUp()
        let sampleStorageService = SampleStorageServiceFake()
        imageStorageService = ImageStorageServiceImpl(sampleStorageService: sampleStorageService)
    }

    override func tearDown() {
        imageStorageService = nil
        super.tearDown()
    }

    func testImageStorageServiceStartsWithNoImages() async throws {
        let images = try await imageStorageService.fetchImages(withLabelID: .init(id: UUID(), projectID: ProjectID()), dataType: .training)
        XCTAssertTrue(images.isEmpty)
    }

    func testImageCannotBeAddedToStorageBeforeLabelIsAdded() async throws {
        let truckImage = UIImage(systemName: "box.truck.fill")!
        let truckLabelID = LabelID(id: UUID(), projectID: ProjectID())
        do {
            try await imageStorageService.add(labeledImage: LabeledImage(image: truckImage, labelID: truckLabelID))
        } catch let e as SampleStorageServiceError {
            guard case let .noSuchLabel(labelID) = e else {
                XCTFail("Unexpected error \(e)")
                return
            }
            XCTAssertEqual(labelID, truckLabelID)
            return
        }
        XCTFail("Expected error not thrown")
    }

    func testImageCanBeAddedToStorage() async throws {
        let truckLabelID = LabelID(id: UUID(), projectID: ProjectID())
        try await imageStorageService.add(label: LabelAnnotation(labelID: truckLabelID,
                                                                 label: "truck"))
        let truckImage = UIImage(systemName: "box.truck.fill")!
        try await imageStorageService.add(labeledImage: LabeledImage(image: truckImage, labelID: truckLabelID))

        // Make sure it was added
        let truckImages = try await imageStorageService.fetchImages(withLabelID: truckLabelID, dataType: .training)
        XCTAssertEqual(truckImages.count, 1)

        // Make sure there are no otherwise-annotated images
        let sunLabelID = LabelID(id: UUID(), projectID: ProjectID())
        let globeImages = try await imageStorageService.fetchImages(withLabelID: sunLabelID, dataType: .training)
        XCTAssertTrue(globeImages.isEmpty)
    }

    func testImagesAreAddedToSeparateStorage() async throws {
        let truckLabelAnnotation = LabelAnnotation(label: "Truck",
                                                   projectID: projectID)
        let secondTruckLabelAnnotation = LabelAnnotation(label: "Truck",
                                                         projectID: anotherProjectID)
        let sunLabelAnnotation = LabelAnnotation(label: "Sun",
                                                 projectID: projectID)
        let secondSunLabelAnnotation = LabelAnnotation(label: "Sun",
                                                       projectID: anotherProjectID)

        try await imageStorageService.add(label: truckLabelAnnotation)
        try await imageStorageService.add(label: sunLabelAnnotation)
        try await imageStorageService.add(label: secondSunLabelAnnotation)

        let truckImage = UIImage(systemName: "box.truck.fill")!
        let anotherTruckImage = UIImage(systemName: "box.truck.badge.clock")!
        try await imageStorageService.add(labeledImage: LabeledImage(image: truckImage, labelID: truckLabelAnnotation.id))
        try await imageStorageService.add(labeledImage: LabeledImage(image: anotherTruckImage, labelID: truckLabelAnnotation.id))

        let sunImage = UIImage(systemName: "sun.max")!
        try await imageStorageService.add(labeledImage: LabeledImage(image: sunImage, labelID: secondSunLabelAnnotation.id))

        // Make sure there are 2 truck images and 0 sun images in the first project
        let firstProjectTruckImages = try await imageStorageService.fetchImages(withLabelID: truckLabelAnnotation.id, dataType: .training)
        let firstProjectSunImages = try await imageStorageService.fetchImages(withLabelID: sunLabelAnnotation.id, dataType: .training)
        XCTAssertEqual(firstProjectTruckImages.count, 2)
        XCTAssertTrue(firstProjectSunImages.isEmpty)

        // Make sure there is 1 sun image and 0 truck images in the second project
        let secondProjectSunImages = try await imageStorageService.fetchImages(withLabelID: secondSunLabelAnnotation.id, dataType: .training)
        let secondProjectTruckImages = try await imageStorageService.fetchImages(withLabelID: secondTruckLabelAnnotation.id, dataType: .training)
        XCTAssertEqual(secondProjectSunImages.count, 1)
        XCTAssertTrue(secondProjectTruckImages.isEmpty)
    }

    func testImageLabelsCanBeFetchedAsExpected() async throws {
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        let sunLabel = LabelAnnotation(label: "Sun", projectID: projectID)

        try await imageStorageService.add(label: truckLabel)
        try await imageStorageService.add(label: sunLabel)

        let truckImage = UIImage(systemName: "box.truck.fill")!
        let anotherTruckImage = UIImage(systemName: "box.truck.badge.clock")!
        let sunImage = UIImage(systemName: "sun.max")!

        try await imageStorageService.add(labeledImage: LabeledImage(image: truckImage, labelID: truckLabel.id))
        try await imageStorageService.add(labeledImage: LabeledImage(image: anotherTruckImage, labelID: truckLabel.id))
        try await imageStorageService.add(labeledImage: LabeledImage(image: sunImage, labelID: sunLabel.id))

        // Make sure the storage service labels are returned as expected.
        let labels = try await imageStorageService.fetchLabels(fromProjectWithID: projectID)
        XCTAssertEqual(labels, [truckLabel, sunLabel])
    }

    func testFetchLabelsReturnsUpdatedLabelString() async throws {
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        let sunLabel = LabelAnnotation(label: "Sun", projectID: projectID)

        try await imageStorageService.add(label: truckLabel)
        try await imageStorageService.add(label: sunLabel)

        // Make sure the storage service labels are returned as expected.
        let labels = try await imageStorageService.fetchLabels(fromProjectWithID: projectID)
        XCTAssertEqual(labels, [truckLabel, sunLabel])

        try await imageStorageService.update(labelWithID: truckLabel.id,
                                             newLabelString: "Truck 2")
        try await imageStorageService.update(labelWithID: sunLabel.id,
                                             newLabelString: "Sun 2")

        let updatedLabels = try await imageStorageService.fetchLabels(fromProjectWithID: projectID)
        XCTAssertEqual(updatedLabels.count, 2)

        XCTAssertEqual(updatedLabels[0].labelString, "Truck 2")
        XCTAssertEqual(updatedLabels[0].id, truckLabel.id)

        XCTAssertEqual(updatedLabels[1].labelString, "Sun 2")
        XCTAssertEqual(updatedLabels[1].id, sunLabel.id)
    }

}
