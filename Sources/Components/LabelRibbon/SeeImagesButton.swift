// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

/// A Label style that places the icon to the right of the title
struct RightIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

struct SeeImagesButton: View {
    let label: LabelAnnotation
    let imageCount: Int
    let navigationLink: ProjectFullScreenRoute

    var body: some View {
        NavigationLink(value: navigationLink) {
            Label {
                Text(.imageCountButtonTitle(imageCount))
            } icon: {
                Image(systemName: "chevron.right")
            }
            .labelStyle(RightIconLabelStyle())
            .font(.callout)
            .padding()
            .contentShape(Rectangle())
        }.padding(.trailing, 20) // value copied from Sketch
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack {
        SeeImagesButton(
            label: .fakeAppleLabel,
            imageCount: 0,
            navigationLink: .fakeCameraRoute
        )
        SeeImagesButton(
            label: .fakeBananaLabel,
            imageCount: 1,
            navigationLink: .fakeCameraRoute
        )
        SeeImagesButton(
            label: .fakeCarrotLabel,
            imageCount: 8,
            navigationLink: .fakeCameraRoute
        )
    }
}

#endif
