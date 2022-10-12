// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct TrainingModelPanel: View {
    enum State: Equatable, Sendable {
        case loading
        case noModelAvailable
        case training
        case previewAvailable(projectID: ProjectID, lastTrained: Date)
    }

    let state: State
    let navigateToTestPage: () -> Void

    var body: some View {
        switch state {
        case .loading:
            EmptyTrainingCardView()

        case .noModelAvailable:
            NoModelView()

        case .training:
            ModelIsTrainingView()

        case let .previewAvailable(projectID, lastTrained):
            PreviewModelView(projectID: projectID, dateLastTrained: lastTrained) {
                navigateToTestPage()
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Loading") {
    TrainingModelPanel(state: .loading) {
        // No-op
    }
    .trainingCardPreviewStyle()
}

#Preview("No model available") {
    TrainingModelPanel(state: .noModelAvailable) {
        // No-op
    }
    .trainingCardPreviewStyle()
}

#Preview("Training") {
    TrainingModelPanel(state: .training) {
        // No-op
    }
    .trainingCardPreviewStyle()
}

#Preview("Preview available") {
    NavigationStack {
        TrainingModelPanel(state: .previewAvailable(projectID: ProjectID(), lastTrained: Date())) {
            // No-op
        }
        .trainingCardPreviewStyle()
    }
}

#endif
