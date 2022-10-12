// Copyright 2026 Apple Inc. All rights reserved.

import OSLog
import SwiftUI

struct NoModelView: View {
    var body: some View {
        VStack {
            Text(.noModelAvailable)
                .trainingCardTitle()

            Text(.trainAModelToTestItHere)
                .trainingCardSubtitle()

            Spacer()
            Image(systemName: "square.stack.3d.up.slash")
                .trainingCardMainImage()
                .foregroundStyle(.secondary)
            Spacer()

            Button {
                assertionFailure("Disabled button")
            } label: {
                Label(.previewModel, systemImage: "camera.fill")
                    .padding(.horizontal, 40)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
            .padding(.bottom, .trainingCard.largePadding)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NoModelView()
        .trainingCardPreviewStyle()
}

#endif
