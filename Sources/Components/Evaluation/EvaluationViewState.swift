// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Tiny struct wrapping metric and grid states.
enum EvaluationViewState {
    case loading
    case loaded(sidebarViewState: EvaluationMetricSidebarViewState,
                gridViewState: EvaluationGridViewState)
}
