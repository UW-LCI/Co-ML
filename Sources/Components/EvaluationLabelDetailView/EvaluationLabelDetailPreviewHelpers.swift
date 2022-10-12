// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

#if DEBUG

extension [GradedCardViewState] {
    static let fakeGradedCardViews: [GradedCardViewState] = [
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana1id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana2id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana3id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana4id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana5id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana6id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana7id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana8id, correct: false),
        .predicted(label: .fakeAppleLabelString, imageID: .fakeBanana9id, correct: false),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple1id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple2id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple3id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple4id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple5id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple6id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple7id, correct: true),
        .predicted(label: .fakeBananaLabelString, imageID: .fakeApple8id, correct: true),
    ]
}

extension GradedCardViewState {
    static func predicted(label: String, imageID: LabeledImageID, correct: Bool) -> Self {
        .init(
            prediction: .labeled(predictedLabel: label, correct: correct),
            imageID: imageID
        )
    }
}

#endif
