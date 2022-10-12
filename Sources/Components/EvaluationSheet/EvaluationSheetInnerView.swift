// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationSheetInnerView: View {
    let state: EvaluationSheetViewState?

    let fetchImage: (UUID) async throws -> UIImage

    let changeExpectedLabel: (LabelID) -> Void
    let delete: () -> Void
    let dismiss: () -> Void
    let moveToTraining: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbarView

            predictionContent
                .padding(34)
                .background(Color(uiColor: .secondarySystemBackground))
        }
        .frame(width: 706)
        .cornerRadius(13)
        .shadow(radius: 5)
    }

    private var toolbarView: some View {
        SharedSheetToolbarView(
            localizedTitle: String(localized: .testingImage),
            deleteButtonAction: delete,
            doneButtonAction: dismiss,
            moveAction: moveToTraining
        )
    }

    @ViewBuilder
    private var predictionContent: some View {
        if let state {
            EvaluationSheetPredictionContent(
                sampleID: state.sampleID,
                predictionState: state.predictionState,
                labels: state.labels,
                selectedLabelID: state.selectedLabelID,
                onLabelSelected: {
                    changeExpectedLabel($0)
                },
                fetchImage: fetchImage)
        } else {
            Spacer()
                .frame(height: 300)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Veggies") {
    EvaluationSheetInnerView.fake(
        predictionState: .fake
    )
}

#Preview("No model") {
    EvaluationSheetInnerView.fake(
        predictionState: .noModel
    )
}

extension EvaluationSheetInnerView {
    static func fake(
        predictionState: EvaluationSheetPredictionState
    ) -> Self {
        .init(
            state: EvaluationSheetViewState(
                sampleID: .fakeApple1SampleUUID,
                predictionState: predictionState,
                labels: .fakeLabels,
                selectedLabelID: .fakeAppleLabelID
            ),
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            changeExpectedLabel: {
                print("Change expected label to \($0)")
            },
            delete: {
                print("Delete")
            },
            dismiss: {
                print("Dismiss")
            },
            moveToTraining: {
                print("Move to training")
            }
        )
    }
}

#endif
