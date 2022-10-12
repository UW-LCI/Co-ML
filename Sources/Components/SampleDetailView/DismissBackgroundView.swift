// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// Use as a presentationBackground
struct DismissBackgroundView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Button(role: .cancel) {
            dismiss()
        } label: {
            Rectangle()
                .foregroundColor(.clear)
                .background(Color.gray.opacity(0.5))
        }
        .accessibilityAction(.escape) {
            dismiss()
        }
    }
}
