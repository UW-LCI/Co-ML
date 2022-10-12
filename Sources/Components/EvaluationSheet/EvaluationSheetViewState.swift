// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A struct wrapping all the database-defined specifications of an evaluation sheet modal view.
struct EvaluationSheetViewState: Identifiable {

    /// The identifier of the sample being evaluated.
    let sampleID: UUID

    /// The prediction state of the evaluation sheet view, including observations and correctness description.
    let predictionState: EvaluationSheetPredictionState

    /// The labels which may be presented as a pop up menu and selected.
    let labels: [LabelAnnotation]

    /// The currently selected label identifier.
    let selectedLabelID: LabelID

    // MARK: - Identifiable

    var id: String {
        "\(sampleID)-\(predictionState.id)-\(selectedLabelID.idString)"
    }
}

extension EvaluationSheetViewState {
    var selectedLabelName: String? {
        labels.first(where: { $0.id == selectedLabelID })?.labelString
    }
}
