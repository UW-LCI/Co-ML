// Copyright 2026 Apple Inc. All rights reserved.

import OSLog
import SwiftUI

struct UpdatesAvailableView: View {
    let progressState: TrainingModelView.ProgressState?
    let changes: [ProjectModelInfo.Change]
    let startTraining: @MainActor () -> Void

    var body: some View {
        VStack {
            Text(.updatesAvailable)
                .trainingCardTitle()

            Text(.reviewChangesSinceTheLastTimeYouTrained)
                .trainingCardSubtitle()

            if let progressState {
                Spacer()
                TrainingModelView(state: progressState)
            } else {
                TrainingChangesView(changes: changes)
                    .padding(.top)
            }

            Spacer()

            Button {
                os_log(.info, "Start Training button tapped")
                startTraining()
            } label: {
                Label(.reTrainModel, systemImage: "play.fill")
                    .padding(.horizontal, 40)
                    .padding(.vertical, 5)
            }
            .disabled(progressState != nil)
            .buttonStyle(.borderedProminent)

            if progressState == nil {
                Text(.thisActionWillReplaceYourCurrentModel)
                    .trainingCardButtonCaption()
            } else {
                Text(verbatim: " ")
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Many changes") {
    UpdatesAvailableView(progressState: nil, changes: [
        .labelRenamed(oldLabelString: "Tangerine", newLabelString: "Orange"),
        .labelDeleted(labelString: "Banana"),
        .labelAdded(labelString: "Cherry"),
        .samplesChanged(addedSampleCount: 7, removedSampleCount: 0, labelString: "Cherry"),
        .samplesChanged(addedSampleCount: 4, removedSampleCount: 3, labelString: "Orange"),
        .samplesChanged(addedSampleCount: 0, removedSampleCount: 1, labelString: "Apple")
    ]) {
        print("Train again")
    }
    .trainingCardPreviewStyle()
}

#Preview("Few changes") {
    UpdatesAvailableView(progressState: nil, changes: [
        .samplesChanged(addedSampleCount: 1, removedSampleCount: 0, labelString: "Cherry"),
    ]) {
        print("Train again")
    }
    .trainingCardPreviewStyle()
}

#Preview("Progress") {
    UpdatesAvailableView(progressState: .init(progress: 0.5, subtitle: "Watering grass…"), changes: []) {
        print("Train again")
    }
    .trainingCardPreviewStyle()
}

#endif
