// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

#if DEBUG

actor SampleDetailRepositoryFake: SampleDetailRepository {
    private let sampleDetails: SampleDetails
    let sampleID: UUID
    let dataType: DataType

    /// Whether this repository throws when asked to update the sample's label.
    let failsToUpdateLabel: Bool

    /// Whether this repository throws when asked to delete the sample.
    let failsToDeleteSample: Bool

    init(sampleDetails: SampleDetails,
         failsToUpdateLabel: Bool = false,
         failsToDeleteSample: Bool = false,
         dataType: DataType = .training) {
        self.sampleDetails = sampleDetails
        self.failsToUpdateLabel = failsToUpdateLabel
        self.failsToDeleteSample = failsToDeleteSample
        self.sampleID = sampleDetails.image.sampleID
        self.dataType = dataType
    }

    // MARK: - SampleDetailRepository

    func fetchSampleDetails() async throws -> SampleDetails {
        try await Task.sleep(seconds: 1) // Simulate a long delay for a nice preview.
        return sampleDetails
    }

    func updateSelectedLabel(labelID: LabelID) async throws {
        if failsToUpdateLabel {
            throw SampleDetailRepositoryError.failedToUpdateLabelID(labelID)
        }
    }

    func deleteSample() async throws {
        if failsToDeleteSample {
            throw SampleDetailRepositoryError.failedToDeleteSample
        }
    }

    func moveToOppositeDataType() async throws {
        throw SampleDetailRepositoryError.failedToMoveSampleToTesting
    }
}

extension SampleDetailRepository where Self == SampleDetailRepositoryFake {
    static var fake: Self {
        .init(
            sampleDetails: .fake
        )
    }
}

#endif
