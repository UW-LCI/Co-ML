// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
@testable import CoMLApp
import UIKit
import UniformTypeIdentifiers
import XCTest

@MainActor
final class SampleDetailRepositoryTests: XCTestCase {
    static let feb7afternoon = Date(timeIntervalSince1970: 1_675_809_660.0) // Feb. 7, 2:41:00pm

    var projectID: ProjectID!
    var project: Project!
    var labelID: LabelID!
    var label: LabelAnnotation!
    var sampleID: UUID!
    var databaseStorageService: DatabaseStorageService!
    var sampleDetailRepository: SampleDetailRepository!

    override func setUp() {
        super.setUp()
        projectID = ProjectID(uuidString: "1f00cd56-82e4-4138-909c-26843537068a")!
        project = Project(id: projectID, title: "Cars", createdAt: Date())
        labelID = LabelID(id: UUID(uuidString: "94460a3f-61a0-4846-bd2e-94580c251e9a")!, projectID: projectID)
        label = LabelAnnotation(labelID: labelID, label: "Honda")
        sampleID = UUID(uuidString: "085f1dcb-4641-4d68-b777-3f36334e2f2b")!

        let sampleData = UIImage(systemName: "box.truck")!.jpegData(compressionQuality: 1.0)!
        let sample = AnnotatedSample(id: sampleID,
                                                      annotation: label,
                                                      sampleType: .jpeg,
                                                      sampleData: sampleData,
                                                      creationDate: Self.feb7afternoon)

        databaseStorageService = DatabaseStorageServiceFake(
            projectsByID: [
                projectID: project
            ],
            samplesByLabelID: [
                labelID: [ sample ]
            ],
            labels: [ label ])

        sampleDetailRepository = SampleDetailRepositoryImpl(
            sampleID: sampleID,
            dataType: .training,
            databaseStorageService: databaseStorageService,
            initialLabelID: labelID)
    }

    func testSampleDetailRepositoryCanFetchSampleDetails() async throws {
        let details = try await sampleDetailRepository.fetchSampleDetails()
        XCTAssertEqual(details.selectedLabelID, labelID)
        XCTAssertEqual(details.labels.count, 1)
        XCTAssertEqual(details.labels.first!, label)
        let image = details.image
        XCTAssertGreaterThan(image.image.size.width, 0)
        XCTAssertGreaterThan(image.image.size.height, 0)
        XCTAssertEqual(image.creationDate, Self.feb7afternoon)
        XCTAssertEqual(image.id.labelID, labelID)
    }
}
