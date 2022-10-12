// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

// used when linking to label dashboard from within the Ribbon View scroll container
struct SeeImagesScrollButton: View {
    let navigationLink: ProjectFullScreenRoute
    let labelName: String

    var body: some View {
        NavigationLink(value: navigationLink) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(uiColor: .secondarySystemBackground))
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(uiColor: .label))
                    .padding(.horizontal, 15)
                    .accessibilityLabel(.showAllImagesFor(labelName))
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    SeeImagesScrollButton(
        navigationLink: .fakeCameraRoute,
        labelName: .fakeAppleLabelString
    )
}

#endif
