// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum EvaluationSheetPredictionState: Identifiable {
    case noModel

    /// The view state when a describable prediction exists with specified observations.
    case predicted(descriptiveLabelState: EvaluationDescriptiveLabelState,
                   observations: [Observation])

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .noModel:
            return "no-model"
        case .predicted(let descriptiveLabelState, _):
            return "predicted-\(descriptiveLabelState.id)"
        }
    }
}

#if DEBUG

extension EvaluationSheetPredictionState {
    static let fake: Self = .predicted(
        descriptiveLabelState: .correct(labelName: "Cucumber"),
        observations: [
            Observation(annotation: "Cucumber", confidence: 0.82),
            Observation(annotation: "Broccoli", confidence: 0.13),
            Observation(annotation: "Bean", confidence: 0.03),
        ]
    )
}

#endif
