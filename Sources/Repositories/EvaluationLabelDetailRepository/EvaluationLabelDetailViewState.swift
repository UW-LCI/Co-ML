// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Possible states of `EvaluationLabelDetailInnerView`.
enum EvaluationLabelDetailViewState {

    case loading

    case loaded(label: LabelAnnotation, cardViewStates: [GradedCardViewState])

    case disappeared(lastKnownLabelTitle: String, lastKnownImageCount: Int)
}
