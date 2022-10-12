// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import os.log
import SwiftUI

struct LabelRibbonViewState {
    let label: LabelAnnotation
    let imageList: [UUID]
    let imageCount: Int

    var imageIDs: [LabeledImageID] {
        imageList.map { LabeledImageID(existingSampleID: $0, labelID: label.id) }
    }
}

#if DEBUG

extension [LabelRibbonViewState] {
    static let fake: Self = [
        .fakeApples,
        .fakeBananas,
        .fakeCarrots
    ]
}

extension LabelRibbonViewState {
    static let fakeApples: Self = .init(
        label: .fakeAppleLabel,
        imageList: .fakeAppleUUIDs,
        imageCount: [UUID].fakeAppleUUIDs.count
    )

    static let fakeBananas: Self = .init(
        label: .fakeBananaLabel,
        imageList: .fakeBananaUUIDs,
        imageCount: [UUID].fakeBananaUUIDs.count
    )

    static let fakeCarrots: Self = .init(
        label: .fakeCarrotLabel,
        imageList: .fakeCarrotUUIDs,
        imageCount: [UUID].fakeCarrotUUIDs.count
    )
}

#endif
