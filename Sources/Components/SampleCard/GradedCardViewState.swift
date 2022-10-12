// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

struct GradedCardViewState: Identifiable {
    enum Prediction: Equatable {
        case labeled(predictedLabel: String, correct: Bool)
        case loading
        case blank
    }

    let prediction: Prediction
    let imageID: LabeledImageID

    var id: UUID {
        imageID.id
    }
}
