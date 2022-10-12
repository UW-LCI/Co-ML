// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct DeleteImageContextMenu: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.contextMenu {
            Button(role: .destructive) {
                action()
            } label: {
                Label(.delete, systemImage: "trash")
                .accessibilityLabel(.deleteImageVoiceOver)
            }
        }
    }
}
