// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor EvaluationLabelDetailRepositoryFake: EvaluationLabelDetailRepository {
    let labelID: LabelID

    private let viewState: EvaluationLabelDetailViewState

    init(labelID: LabelID, viewState: EvaluationLabelDetailViewState) {
        self.labelID = labelID
        self.viewState = viewState
    }

    // MARK: - EvaluationLabelDetailRepository

    func fetchEvaluationLabelDetailViewState() async -> EvaluationLabelDetailViewState {
        viewState
    }
}
