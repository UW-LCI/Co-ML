// Copyright 2026 Apple Inc. All rights reserved.

import OSLog
import SwiftUI

struct ReadyToTrainView: View {
    let trainableLabelCount: Int
    let progressState: TrainingModelView.ProgressState?
    let startTraining: @MainActor () -> Void

    var body: some View {
        VStack {
            Text(.readyToTrain)
                .trainingCardTitle()

            Text(.youHaveLabelsWithEnoughImagesToTrain(trainableLabelCount))
                .trainingCardSubtitle()
            Spacer()

            if let progressState {
                TrainingModelView(state: progressState)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .trainingCardMainImage()
                    .foregroundColor(Color(uiColor: .systemGreen))
            }

            Spacer()

            Button {
                os_log(.info, "Start Training button tapped")
                startTraining()
            } label: {
                Label(.trainModel, systemImage: "play.fill")
                    .padding(.horizontal, 40)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, .trainingCard.largePadding)
            .disabled(progressState != nil)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Not in progress") {
    ReadyToTrainView(
        trainableLabelCount: 5,
        progressState: nil
    ) {
        print("Train model")
    }
    .trainingCardPreviewStyle()
}

#Preview("In progress") {
    ReadyToTrainView(
        trainableLabelCount: 5,
        progressState: .fake
    ) {
        print("Train model")
    }
    .trainingCardPreviewStyle()
}

#endif
