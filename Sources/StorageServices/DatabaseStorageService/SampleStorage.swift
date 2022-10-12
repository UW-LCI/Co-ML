// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Fetches and updates data specific to a single annotated sample.
protocol SampleStorage {
    associatedtype Annotation: Codable
    var sample: AnnotatedSample { get }

    /// Publishes updates to the  sample.
    var samplePublisher: Published<AnnotatedSample>.Publisher { get }

    /// Update annotation.
    ///
    /// - Parameter annotation: New annotation.
    func update(annotation: Annotation) async throws
}
