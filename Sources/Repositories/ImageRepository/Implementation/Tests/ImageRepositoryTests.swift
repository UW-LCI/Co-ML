// Copyright 2026 Apple Inc. All rights reserved.

@testable import CoMLApp
import UIKit
import XCTest
@testable import CoMLApp

final class ImagesRepositoryTests: XCTestCase {
    private let projectID = UUID(uuidString: "a5955e70-f30e-4593-ba77-3a8947ed30a8")!

    private var imageRepository: ImageRepository!

    override func setUp() {
        super.setUp()
        let sampleStorageService = SampleStorageServiceFake()
        let imageStorageService = ImageStorageServiceImpl(sampleStorageService: sampleStorageService)
        imageRepository = ImageRepositoryImpl(projectID: projectID, imageStorageService: imageStorageService)
    }

    override func tearDown() {
        imageRepository = nil
        super.tearDown()
    }

    func testAddImageThrowsIfNoLabelExists() async throws {
        let labelID = LabelID(id: UUID(), projectID: projectID)
        let truckImage = UIImage(systemName: "box.truck.fill")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: labelID)
        do {
            try await imageRepository.add(labeledImage: truckLabeledImage)
        } catch let e as SampleStorageServiceError {
            guard case let .noSuchLabel(noSuchLabelID) = e else {
                XCTFail("Unexpected error \(e)")
                return
            }
            XCTAssertEqual(noSuchLabelID, labelID)
            return
        }
        XCTFail("Expected an error, but none was thrown")
    }

    func testAddLabelAndImageDoesNotThrow() async throws {
        let truckLabel = LabelAnnotation(label: "Truck", projectID: projectID)
        try await imageRepository.add(label: truckLabel)

        let truckImage = UIImage(systemName: "box.truck.fill")!
        let truckLabeledImage = LabeledImage(image: truckImage, labelID: truckLabel.id)
        try await imageRepository.add(labeledImage: truckLabeledImage)
    }
}
