// Copyright 2026 Apple Inc. All rights reserved.

import OSLog
import SwiftUI

struct NoUpdatesView: View {
    var body: some View {
        VStack {
            Text(.noUpdates)
                .trainingCardTitle()

            Text(.yourModelIsTrainedOnTheLatestData)
                .trainingCardSubtitle()

            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .trainingCardMainImage()
                .foregroundColor(Color(uiColor: .systemGreen))
            Spacer()

            Button {
                assertionFailure("This button should be disabled")
            } label: {
                Label(.trainModel, systemImage: "play.fill")
                    .padding(.horizontal, 40)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, .trainingCard.largePadding)
            .disabled(true)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NoUpdatesView()
        .trainingCardPreviewStyle()
}

#endif
