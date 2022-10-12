// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Generic classifier.
protocol Classifier: Actor {
    associatedtype Annotation: Codable

    /// Representation of the data to be classified; `UIImage` in image classification for example.
    associatedtype Sample

    init(modelURL: URL) async throws

    /// Classify a sample.
    ///
    /// - Parameter sample: Sample to be classified.
    /// - Returns: Classification prediction.
    func classify(sample: Sample) async throws -> Prediction
}
