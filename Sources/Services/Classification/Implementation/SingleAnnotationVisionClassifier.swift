// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Vision
import CoreImage
import UIKit

final actor SingleAnnotationVisionClassifier {
    enum ClassificationError: Error {
        case unableToConvertToCIImage
    }

    typealias CoreMLRequestContinuation = CheckedContinuation<VNRequest, Error>
    private let visionModel: VNCoreMLModel

    /// Initialize to kick off training. This is complete once the the `VNCoreMLModel` is ready, enabling classification.
    ///
    /// - Parameter modelURL: URL where the model **will** be stored.
    init(modelURL: URL) async throws {
        // Background to keep it off the main thread.
        let task = Task {
            let compiledModelUrl = try MLModel.compileModel(at: modelURL)
            let baseModel = try MLModel(contentsOf: compiledModelUrl)
            return try VNCoreMLModel(for: baseModel)
        }
        self.visionModel = try await task.value
    }

    /// Classify an image and asynchronously return a prediction.
    ///
    /// - Parameter sample: The `UIImage` we want to classify.
    /// - Returns: A prediction.
    func classify(sample: UIImage) async throws -> Prediction {
        // `CIImage` isn't Sendable, whereas `UIImage` is, so the API
        // takes in a `UIImage`.
        guard let sample = CIImage(image: sample) else {
            throw ClassificationError.unableToConvertToCIImage
        }

        let vnRequest = try await withCheckedThrowingContinuation { (continuation: CoreMLRequestContinuation) in
            let vnCoreMLRequest = VNCoreMLRequest(model: visionModel) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: request)
            }

            let handler = VNImageRequestHandler(ciImage: sample)
            do {
                try handler.perform([vnCoreMLRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }

        let results = vnRequest.results as? [VNClassificationObservation] ?? []
        let predictions = results.map { Observation(annotation: $0.identifier, confidence: CGFloat($0.confidence)) }

        return Prediction(
            observations: predictions
        )
    }
}

/// Declare `VNCoreMLModel` as retroactively sendable.
extension VNCoreMLModel: @unchecked Sendable { }
