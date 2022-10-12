// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct CameraModeToggle: View {
    @Binding var mode: CameraViewMode

    @ScaledMetric var scale = 1

    var body: some View {
        TabView(selection: $mode) {
            ForEach(CameraViewMode.allCases, id: \.description) { mode in
                // The body of the tab is just the name of the mode
                // The camera UI also changes in the background
                VStack {
                    Spacer()
                    Text(mode.description)
                        .padding(.bottom, 50) // prevents the content slipping under the pager
                }
                .tag(mode)
                .tabItem {
                    Text(mode.description) // Does not display: provides accessibility name
                }
            }
        }
        .frame(height: scale * 40 + 50) // Create enough space for the tab control and content
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .accessibilityElement(children: .combine) // make the whole switcher one big control
        .accessibilityLabel(.cameraMode)
        .accessibilityHint(.collectDataOrTestModel)
        .accessibilityInputLabels([
            String(localized: .cameraMode),
            String(localized: .mode),
            String(localized: .preview),
            String(localized: .previewModel),
            String(localized: .collectData)
        ])
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Collect Data") {
    CameraModeToggle(mode: .constant(.collectionMode))
}

#Preview("Preview Model") {
    CameraModeToggle(mode: .constant(.classificationMode))
}

#endif
