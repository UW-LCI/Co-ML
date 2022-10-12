// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import XCTest
@testable import CoMLApp

@MainActor
final class SampleDetailViewModelUnitTests: XCTestCase {
    static let feb7afternoon = Date(timeIntervalSince1970: 1_675_809_660.0) // Feb. 7, 2:41:00pm

    static let projectID = ProjectID(uuidString: "428a79af-201b-48e9-9d3a-5e12b27ef5f6")!
    static let appleLabelID = LabelID(id: UUID(uuidString: "f56907f9-6f0a-4ddb-ad2f-72ce66c590b7")!, projectID: projectID)
    static let bananaLabelID = LabelID(id: UUID(uuidString: "ca986f0c-239d-4345-a9f3-18be24d94563")!, projectID: projectID)
    static let strawberryLabelID = LabelID(id: UUID(uuidString: "5f588319-187c-4bff-92cb-246ee0b3d58c")!, projectID: projectID)
    static let labels = [
         LabelAnnotation(labelID: appleLabelID, label: "Apple"),
         LabelAnnotation(labelID: bananaLabelID, label: "Banana"),
         LabelAnnotation(labelID: strawberryLabelID, label: "Strawberry")
     ]

    static let labeledImageID = LabeledImageID(existingSampleID: UUID(uuidString: "1a327699-fdaa-4d19-9a00-5572885e79af")!, labelID: bananaLabelID)
    static let labeledImage = LabeledImage(existingLabeledImageID: labeledImageID,
                                     image: UIImage(systemName: "box.truck")!,
                                     creationDate: feb7afternoon)
    static let sampleDetails = SampleDetails(image: labeledImage, labels: labels, selectedLabelID: bananaLabelID)

    var cancellables: Set<AnyCancellable> = Set()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testSampleDetailFetchUpdatesViewModelPublishedProperty() async throws {
        let repository = SampleDetailRepositoryFake(sampleDetails: Self.sampleDetails)
        let viewModel = SampleDetailSheetViewModel(sampleDetailRepository: repository, fetch: false)
        XCTAssertNil(viewModel.sampleDetails)
        XCTAssertFalse(viewModel.showToolbar)

        viewModel.fetchSampleDetails()

        for try await detail in viewModel.$sampleDetails.values where detail != nil {
            break
        }

        XCTAssertNotNil(viewModel.sampleDetails)
        XCTAssertTrue(viewModel.showToolbar)
    }

    func testLabelChangeYieldsOptimisticSampleDetailsUpdate() async throws {
        let repository = SampleDetailRepositoryFake(sampleDetails: Self.sampleDetails)
        let viewModel = SampleDetailSheetViewModel(sampleDetailRepository: repository, fetch: false)

        var detailsAsyncIterator = viewModel.$sampleDetails
            .timeout(5)
            .values.makeAsyncIterator()

        let initialValue = try await detailsAsyncIterator.next()!
        XCTAssertNil(initialValue)

        viewModel.fetchSampleDetails()
        let valueAfterInitialFetch = try await detailsAsyncIterator.next()!
        XCTAssertNotNil(valueAfterInitialFetch)

        viewModel.updateSelectedLabel(labelID: Self.appleLabelID)
        _ = try await detailsAsyncIterator.next()
        XCTAssertEqual(viewModel.sampleDetails?.selectedLabelID, Self.appleLabelID)
    }

    func testFailingRepositoryYieldsRevertedSampleDetails() async throws {
        let failingRepository = SampleDetailRepositoryFake(sampleDetails: Self.sampleDetails, failsToUpdateLabel: true)
        let viewModel = SampleDetailSheetViewModel(sampleDetailRepository: failingRepository, fetch: false)

        var detailsAsyncIterator = viewModel.$sampleDetails
            .timeout(5)
            .values.makeAsyncIterator()

        let initialValue = try await detailsAsyncIterator.next()!
        XCTAssertNil(initialValue)

        viewModel.fetchSampleDetails()
        let valueAfterInitialFetch = try await detailsAsyncIterator.next()!
        XCTAssertNotNil(valueAfterInitialFetch)

        // Then update the label.
        viewModel.updateSelectedLabel(labelID: Self.appleLabelID)
        _ = try await detailsAsyncIterator.next()
        XCTAssertEqual(viewModel.sampleDetails?.selectedLabelID, Self.appleLabelID)

        // Then, expect another update which reverts the optimistic update.
        _ = try await detailsAsyncIterator.next()
        XCTAssertEqual(viewModel.sampleDetails?.selectedLabelID, Self.bananaLabelID)
    }

    func testDeleteSampleResetsDetailsToNil() async throws {
        let repository = SampleDetailRepositoryFake(sampleDetails: Self.sampleDetails)
        let viewModel = SampleDetailSheetViewModel(sampleDetailRepository: repository, fetch: false)
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
        let valueAfterDelete = try await detailsAsyncIterator.next()!
        XCTAssertNil(valueAfterDelete)
    }
}

private struct Timeout: Error {
    let seconds: TimeInterval
}

/// Publisher extension allowing a timeout to be attached to any publisher.
extension Publisher where Failure == Never {
    func timeout(_ timeout: TimeInterval) -> AnyPublisher<Output, Error> {
        let timeout = Timer.publish(every: timeout, on: .main, in: .default)
            .autoconnect()
            .tryMap { _ -> Output in
                throw Timeout(seconds: timeout)
            }
        return timeout.merge(with: self.tryMap { $0 }).eraseToAnyPublisher()
    }
}
