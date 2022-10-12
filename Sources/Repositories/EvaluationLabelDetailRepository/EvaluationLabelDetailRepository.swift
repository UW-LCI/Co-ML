// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

protocol EvaluationLabelDetailRepository: Sendable {

    var labelID: LabelID { get }

    func fetchEvaluationLabelDetailViewState() async -> EvaluationLabelDetailViewState
}
