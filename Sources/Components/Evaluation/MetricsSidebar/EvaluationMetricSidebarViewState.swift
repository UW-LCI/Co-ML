// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Defines the content of `EvaluationMetricSidebar` with static state.
///
/// Instances of this state may be streamed by `EvaluationMetricsRepository`, allowing all types of state transitions to
/// occur, from loaded with metrics, to no model, and back again. No state is intrinsically "final."
enum EvaluationMetricSidebarViewState {

    /// Loaded with the given metrics. Implies the existence of a model and testing data.
    case loaded(metrics: EvaluationMetrics)

    /// Loaded with no model. Implies no model exist, but a project exists with labels and possibly samples.
    case noModel(labels: [LabelWithSampleCount])

    // Loaded metrics with a model but no testing data.  Implies that a model exists but there is no test data for evaluating the model.
    case modelWithoutData(projectID: ProjectID)

    /// Something went terribly wrong determining evaluation metrics, so we can't display anything.
    case failed(error: Error)
}
