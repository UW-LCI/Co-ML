// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EmptyTrainingCardView: View {
    var body: some View {
        Spacer()
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    EmptyTrainingCardView()
        .trainingCardPreviewStyle()
}

#endif
