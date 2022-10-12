// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import UniformTypeIdentifiers
import XCTest
@testable import CoMLApp

@MainActor
final class SampleDetailViewModelIntegrationTests: XCTestCase {
    static let feb7afternoon = Date(timeIntervalSince1970: 1_675_809_660.0) // Feb. 7, 2:41:00pm

    static let projectID = ProjectID(uuidString: "91dd473b-2ee2-4f26-a0c7-f37fb6c6d3e1")!
    static let appleLabelID = LabelID(
        id: UUID(uuidString: "266c5cdb-57f5-44be-975b-e46a9fa51cc4")!,
        projectID: projectID
    )
    static let bananaLabelID = LabelID(
        id: UUID(uuidString: "d6d53d1d-0637-4b7a-ba73-443fe93e59e6")!,
        projectID: projectID
    )
    static let strawberryLabelID = LabelID(
        id: UUID(uuidString: "00649c1a-14b8-4eed-8f77-268fcc9f92b8")!,
        projectID: projectID
    )
    static let labels = [
        LabelAnnotation(labelID: appleLabelID, label: "Apple"),
        LabelAnnotation(labelID: bananaLabelID, label: "Banana"),
        LabelAnnotation(labelID: strawberryLabelID, label: "Strawberry")
    ]

    static let labeledImageID = LabeledImageID(
        existingSampleID: UUID(uuidString: "edf33907-16f5-40b3-8a0a-e8bd412f8723")!,
        labelID: bananaLabelID
    )
    static let labeledImage = LabeledImage(existingLabeledImageID: labeledImageID,
                                           image: UIImage(systemName: "box.truck")!,
                                           creationDate: feb7afternoon)
    static let sampleDetails = SampleDetails(image: labeledImage, labels: labels, selectedLabelID: bananaLabelID)

    static let bananaSample = AnnotatedSample(
        id: labeledImageID.id,
        annotation: LabelAnnotation(labelID: bananaLabelID, label: "Banana"),
        sampleType: .jpeg,
        sampleData: UIImage(systemName: "box.truck")!.jpegData(compressionQuality: 1.0)!,
        creationDate: feb7afternoon
    )

    var cancellables: Set<AnyCancellable> = Set()

    var databaseStorageService: DatabaseStorageService!
    var repository: SampleDetailRepository!
    var viewModel: SampleDetailSheetViewModel!

    override func setUp() {
        super.setUp()
        databaseStorageService = DatabaseStorageServiceFake(
            samplesByLabelID: [Self.bananaLabelID: [ Self.bananaSample ]],
            labels: Self.labels)

        repository = SampleDetailRepositoryImpl(sampleID: Self.labeledImageID.id,
                                                dataType: .training,
                                                databaseStorageService: databaseStorageService,
                                                initialLabelID: Self.bananaLabelID)

        viewModel = SampleDetailSheetViewModel(sampleDetailRepository: repository)
    }

    override func tearDown() {
        viewModel = nil
        repository = nil
        databaseStorageService = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testSampleDetailFetchUpdatesViewModelPublishedProperty() async throws {
        XCTAssertNil(viewModel.sampleDetails)

        viewModel.fetchSampleDetails()
        for try await detail in viewModel.$sampleDetails.values
        where detail != nil {
            break
        }

        XCTAssertNotNil(viewModel.sampleDetails)
    }

    func testDeleteSampleResetsDetailsToNil() async throws {
        var detailsAsyncIterator = viewModel.$sampleDetails
            .timeout(5)
            .values.makeAsyncIterator()

        // Check initial value is nil.
        let initialValue = try await detailsAsyncIterator.next()!
        XCTAssertNil(initialValue)

        // Check details are available after fetch.
        viewModel.fetchSampleDetails()
        let valueAfterInitialFetch = try await detailsAsyncIterator.next()!
        XCTAssertNotNil(valueAfterInitialFetch)

        // Check delete yields nil sample.
        try await viewModel.delete()

        // The 'delete' function yields 2 published changes because it modifies 2 properties.
        _ = try await detailsAsyncIterator.next()!
        let finalValue = try await detailsAsyncIterator.next()!
        XCTAssertNil(finalValue)
    }
}

