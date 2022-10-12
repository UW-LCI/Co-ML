// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct DeleteImagePrompt: ViewModifier {
    @Binding var promptState: DeleteImagePromptState?
    let deleteImage: (LabeledImageID) -> Void

    func body(content: Content) -> some View {
        content.alert(
            alertTitle,
            isPresented: isPresented,
            presenting: $promptState,
            actions: { $promptState in
                if let imageID = promptState?.imageID {
                    Button(role: .destructive) {
                        deleteImage(imageID)
                    } label: {
                        Label(.delete, systemImage: "trash")
                        .accessibilityLabel(.deleteImageVoiceOver)
                    }
                }
            },
            message: { _ in
                Text(.thisActionCannotBeUndone)
            })
    }

    // MARK: - Private

    /// Because alertTitle is required to be non-nil, we default to an empty string when no
    /// alert is displayed.
    private var alertTitle: String {
        promptState?.alertTitle ?? ""
    }

    /// Whether the view is presented, derived from whether `promptState` is `nil`.
    ///
    /// **Note:** This is _set_ to `false` directly via its alert's default `cancel` behavior,
    /// but should never be set to `true`.
    private var isPresented: Binding<Bool> {
        Binding<Bool> {
            promptState != nil
        } set: { newState in
            assert(!newState, "Unexpected direct assignment to isPresented = true")
            promptState = nil
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Normal prompt") {
    Text(verbatim: "Button")
        .modifier(
            DeleteImagePrompt(
                promptState: .constant(.fakeDeleteApplePrompt)
            ) {
                print("Confirm delete apple '\($0)'")
            }
        )
}

#Preview("No label name") {
    Text(verbatim: "Button")
        .modifier(
            DeleteImagePrompt(
                promptState: .constant(.fakeDeleteUnknownLabelPrompt)
            ) { imageID in
                print("User has requested to delete image:", imageID)
            }
        )
}

#endif
