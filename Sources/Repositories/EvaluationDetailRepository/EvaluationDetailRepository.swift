// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A repository allowing details, including evaluation state, to be fetched for a particular sample.
protocol EvaluationDetailRepository: Sendable {

    /// The repository sample's ID.
    var sampleID: UUID { get }

    /// Fetches sample details corresponding to this repository's sample ID.
    func fetchEvaluationDetails() async throws -> EvaluationDetails

    /// Updates the expected label in the repository. Throws if the update failed.
    func changeExpectedLabel(labelID: LabelID) async throws

    /// Deletes the sample repository's sample.
    func deleteSample() async throws

    /// Moves the sample repository's sample to training data.
    func moveToTrainingData() async throws
}
