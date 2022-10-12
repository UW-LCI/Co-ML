// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A struct used to configure the presentation of a "Delete image" prompt.
struct DeleteImagePromptState {

    /// The image ID in consideration for deletion.
    let imageID: LabeledImageID

    /// The label name in which the image in consideration for deletion currently resides, or `nil` if unknown.
    let labelName: String?

    /// The prompt's alert title.
    var alertTitle: String {
        guard let labelName else {
            return String(localized: .deleteThisImage)
        }
        return String(localized: .deleteImage(labelName))
    }
}

#if DEBUG

extension DeleteImagePromptState {
    static let fakeDeleteApplePrompt: Self = .init(
        imageID: .fakeApple1id,
        labelName: .fakeAppleLabelString
    )

    static let fakeDeleteUnknownLabelPrompt: Self = .init(
        imageID: .fakeApple1id,
        labelName: nil
    )
}

#endif
