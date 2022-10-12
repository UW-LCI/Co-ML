// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct LabelWithSampleCount: Identifiable {
    let label: LabelAnnotation
    let sampleCount: Int

    // MARK: - Identifiable
    var id: UUID {
        label.id.id
    }
}

#if DEBUG

extension [LabelWithSampleCount] {
    static let fakeLabelsWithSampleCount: Self = [
        .fakeAppleLabelWithSampleCount,
        .fakeBananaLabelWithSampleCount,
        .fakeCarrotLabelWithSampleCount
    ]
}

extension LabelWithSampleCount {
    static let fakeAppleLabelWithSampleCount = Self(label: .fakeAppleLabel, sampleCount: 123)
    static let fakeBananaLabelWithSampleCount = Self(label: .fakeBananaLabel, sampleCount: 456)
    static let fakeCarrotLabelWithSampleCount = Self(label: .fakeCarrotLabel, sampleCount: 789)
}

#endif
