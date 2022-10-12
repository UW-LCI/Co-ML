// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct CameraLabelOverlay: View {

    let labelString: String

    var body: some View {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(.labelCameraOverlayHint(labelString))
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(uiColor: .systemYellow))
                        .cornerRadius(5)
                }
            }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    CameraLabelOverlay(labelString: "Frogs")
}

#endif
