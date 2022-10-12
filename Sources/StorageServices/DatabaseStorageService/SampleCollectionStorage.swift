// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// API for accessing a collection of samples.
protocol SampleCollectionStorage {
    /// Publisher for changes in each sample's store.
    var samplesPublisher: Published<[any SampleStorage]>.Publisher { get }

    /// Load samples from store.
    func loadSamples() async throws

    /// Add a sample to the store.
    ///
    /// - Parameter sample: Sample to be added.
    func add(sample: AnnotatedSample) async throws

    /// Delete sample from store.
    ///
    /// - Parameter id: `id` of project to be deleted.
    func deleteSample(id: UUID) async throws
}
