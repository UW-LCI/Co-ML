// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A classification result with observations of various confidence.
struct Prediction: Sendable {
    let observations: [Observation]
}

struct Observation: Sendable {
    let annotation: String
    let confidence: Double
}

extension Double {
    var localizedConfidenceDisplayText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}

extension Prediction {

    /// Prediction correctness check.
    /// - Parameters:
    ///   - labelID: LabelID associated with the "testing" labeled image.
    ///   - labels: Labels, used for cross-referencing label string.
    /// - Returns: Whether this prediction is correct in the given context.
    func isCorrect(labelID: LabelID, labels: [LabelAnnotation]) -> Bool {
        guard let topPredictedLabelString = observations.first?.annotation else {
            return false
        }
        guard let labelWithID = labels.first(where: { $0.id == labelID }) else {
            return false
        }
        return labelWithID.matches(labelString: topPredictedLabelString)
    }
}

#if DEBUG

extension [Observation] {

    static let fake: Self = [
        .init(annotation: "Apple", confidence: 0.73),
        .init(annotation: "Mango", confidence: 0.37),
        .init(annotation: "Banana", confidence: 0.0),
        .init(annotation: "Lemon", confidence: 0.0),
    ]

    static let fakeSmallList: Self = [
        .init(annotation: "Apple", confidence: 0.73),
        .init(annotation: "Mango", confidence: 0.37)
    ]

    static let fakeLargeList: Self = [
        .init(annotation: "Apple", confidence: 0.73),
        .init(annotation: "Mango", confidence: 0.15),
        .init(annotation: "Cherry", confidence: 0.04),
        .init(annotation: "Blueberry", confidence: 0.02),
        .init(annotation: "Strawberry", confidence: 0.02),
        .init(annotation: "Orange", confidence: 0.02),
        .init(annotation: "Banana", confidence: 0.0),
        .init(annotation: "Lemon", confidence: 0.0),
        .init(annotation: "Lime", confidence: 0.0),
        .init(annotation: "Rambutan", confidence: 0.0),
    ]
}

#endif
