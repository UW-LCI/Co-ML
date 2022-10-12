// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import SwiftUI

struct PredictionSummaryViewState {
    let image: UIImage
    let observations: [Observation]
    let currentLabels: [LabelAnnotation]

    /// Returns index of current labels that matches the model's prediction
    /// If there is no match, returns the first label
    /// If there are no labels in currentLabels, returns nil
    var selectedLabel: LabelAnnotation? {
        let modelLabel = firstObservation.annotation
        let match = currentLabels.first(where: { appLabel in
            appLabel.matches(labelString: modelLabel)
        })
        return match ?? currentLabels.first
    }

    var firstObservation: Observation {
        guard let firstObservation = observations.first else {
            assertionFailure("No observation was found")
            return Observation(annotation: "", confidence: 0.0)
        }
        return firstObservation
    }

    var predictionConfidencePrefix: String {
        let confidence = firstObservation.confidence.localizedConfidenceDisplayText
        return "The model is \(confidence) confident this is "
    }

    var predictedLabel: String {
        return firstObservation.annotation
    }
}

#if DEBUG

extension PredictionSummaryViewState {

    static let fake = Self(
        image: UIImage(systemName: "tornado")!,
        observations: .fake,
        currentLabels: .fakeLabels
    )

    static let fakeLargeState = Self(
        image: UIImage(systemName: "tornado")!,
        observations: .fakeLargeList,
        currentLabels: .fakeLabels
    )

    static let fakeSmallState = Self(
        image: UIImage(systemName: "tornado")!,
        observations: .fakeSmallList,
        currentLabels: .fakeLabels
    )
}

#endif
