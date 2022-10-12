// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A repository allowing details to be fetched for a particular sample, and for associated labels to be updated.
protocol SampleDetailRepository: Sendable {

    /// The repository sample's ID.
    var sampleID: UUID { get }

    /// The repository sample's data type.
    var dataType: DataType { get }

    /// Fetches sample details corresponding to this repository's sample ID.
    func fetchSampleDetails() async throws -> SampleDetails

    /// Updates the selected label in the repository. Throws if the update failed.
    func updateSelectedLabel(labelID: LabelID) async throws

    /// Deletes the sample repository's sample.
    func deleteSample() async throws

    /// Moves the sample repository's sample to testing data.
    func moveToOppositeDataType() async throws
}
