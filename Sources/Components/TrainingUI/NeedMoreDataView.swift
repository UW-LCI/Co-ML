// Copyright 2026 Apple Inc. All rights reserved.

import OSLog
import SwiftUI

struct NeedMoreDataView: View {
    var body: some View {
        VStack {
            Text(.moreDataNeeded)
                .trainingCardTitle()

            Text(.addAtLeast2LabelsEtc)
                .trainingCardSubtitle()

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
    NeedMoreDataView()
        .trainingCardPreviewStyle()
}

#endif
