// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct SampleDetails {
    let image: LabeledImage
    let labels: [LabelAnnotation]
    let selectedLabelID: LabelID
}

#if DEBUG

extension SampleDetails {
    static let fake: Self = .init(
        image: .fakeApple1,
        labels: .fakeLabels,
        selectedLabelID: .fakeAppleLabelID
    )
}

#endif
