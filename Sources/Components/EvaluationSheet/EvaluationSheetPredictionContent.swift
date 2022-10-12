// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationSheetPredictionContent: View {
    let sampleID: UUID

    let predictionState: EvaluationSheetPredictionState

    let labels: [LabelAnnotation]
    let selectedLabelID: LabelID
    let onLabelSelected: (LabelID) -> Void

    let fetchImage: (UUID) async throws -> UIImage

    var body: some View {
        LabeledContent {
            predictionArea
                .padding(.leading, 34)

        } label: {
            SampleImageView {
                try await fetchImage(sampleID)
            }
            .frame(width: 300, height: 300)
            .scaledToFit()
            .cornerRadius(10)
        }
        .frame(height: 300)
    }

    private var predictionArea: some View {
        VStack(spacing: 40) {

            switch predictionState {

            case .noModel:

                // When there is no model, 2 stacked elements are replaced with 1.
                Spacer()
                Label {
                    Text(.noModelAvailable)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
                Spacer()

            case .predicted(let descriptiveLabelState, let observations):

                // When prediction is available, we show the prediction label and a chart.
                EvaluationDescriptiveLabel(state: descriptiveLabelState)
                    .foregroundColor(.primary)

                EvaluationSheetPredictionChart(observations: observations)
            }

            EvaluationLabelSelectionView(
                labels: labels,
                selectedLabelID: selectedLabelID,
                onLabelSelected: onLabelSelected)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack {
        EvaluationSheetPredictionContent(
            sampleID: .fakeAppleLabelUUID,
            predictionState: .fake,
            labels: .fakeLabels,
            selectedLabelID: .fakeBananaLabelID,
            onLabelSelected: {
                print("label \($0) selected")
            },
            fetchImage: ImageFetchRepositoryFake.fetchImage
        )
        Spacer()
    }
}

#endif
