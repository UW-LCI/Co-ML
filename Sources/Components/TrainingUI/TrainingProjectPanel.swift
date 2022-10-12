// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct TrainingProjectPanel: View {
    enum State: Equatable, Sendable {
        case loading

        case moreDataNeeded

        case readyToTrain(trainableLabelCount: Int, progressState: TrainingModelView.ProgressState?)

        case updatesAvailable(progressState: TrainingModelView.ProgressState?, changes: [ProjectModelInfo.Change])

        case noUpdatesAvailable
    }

    let state: State
    let startTraining: () -> Void

    var body: some View {
        switch state {
        case .loading:
            EmptyTrainingCardView()

        case .moreDataNeeded:
            NeedMoreDataView()

        case let .readyToTrain(trainableLabelCount, progressState):
            ReadyToTrainView(trainableLabelCount: trainableLabelCount, progressState: progressState) {
                startTraining()
            }

        case let .updatesAvailable(progressState, changes):
            UpdatesAvailableView(progressState: progressState, changes: changes) {
                startTraining()
            }

        case .noUpdatesAvailable:
            NoUpdatesView()
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Loading") {
    TrainingProjectPanel(state: .loading) {
        // Unreachable while loading
    }
    .trainingCardPreviewStyle()
}

#Preview("More data needed") {
    TrainingProjectPanel(state: .moreDataNeeded) {
        // Unreachable with more data needed
    }
    .trainingCardPreviewStyle()
}

#Preview("Ready to train, Idle") {
    TrainingProjectPanel(
        state: .readyToTrain(trainableLabelCount: 10, progressState: nil)
    ) {
        print("Start training")
    }
    .trainingCardPreviewStyle()
}

#Preview("Ready to train, Progress") {
    TrainingProjectPanel(
        state: .readyToTrain(trainableLabelCount: 10, progressState: .init(progress: 0.5, subtitle: "Duplicating bugs…"))
    ) {
        // Unreachable in progress
    }
    .trainingCardPreviewStyle()
}

#Preview("Updates available, Idle") {
    TrainingProjectPanel(
        state: .updatesAvailable(
            progressState: nil,
            changes: .fakeProjectChanges
        )
    ) {
        print("Start training")
    }
    .trainingCardPreviewStyle()
}

#Preview("Updates available, Progress") {
    TrainingProjectPanel(
        state: .updatesAvailable(
            progressState: .init(progress: 0.5, subtitle: "Duplicating bugs…"),
            changes: []
        )
    ) {
        // Unreachable in progress
    }
    .trainingCardPreviewStyle()
}

#Preview("No updates") {
    TrainingProjectPanel(state: .noUpdatesAvailable) {
        // Unreachable with no updates
    }
    .trainingCardPreviewStyle()
}

#endif
