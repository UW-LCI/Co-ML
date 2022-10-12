// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct TrainingModelView: View {
    struct ProgressState: Equatable {
        let progress: Float
        let subtitle: String
    }

    let state: ProgressState

    var body: some View {
        VStack {
            Text(.trainingAModel)

            ProgressView(value: state.progress)
                .frame(width: 350)
                .padding()

            Text(state.subtitle)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    TrainingModelView(state: .fake)
}

extension TrainingModelView.ProgressState {
    static let fake: Self = .init(
        progress: 0.5,
        subtitle: "Reticulating splines…"
    )
}

#endif
