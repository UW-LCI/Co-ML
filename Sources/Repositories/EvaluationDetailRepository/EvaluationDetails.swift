// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Evaluation details that may be used to configure an evaluation sheet modal view.
struct EvaluationDetails: Sendable {

    /// The evaluated image, which should include a prediction if there is any model.
    let image: EvaluatedImage

    /// All the available labels for this project.
    let labels: [LabelAnnotation]

    /// The expected label ID.
    let expectedLabelID: LabelID
}
