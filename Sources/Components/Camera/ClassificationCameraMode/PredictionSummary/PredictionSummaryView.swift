// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct PredictionSummaryView: View {
    let state: PredictionSummaryViewState
    let dismiss: () -> Void
    let savePhoto: (UIImage, LabelAnnotation?, DataType) -> Void

    @State private var selectedLabel: LabelAnnotation?
    @State private var saveDestination: DataType = .testing // default

    init(state: PredictionSummaryViewState,
         dismiss: @escaping () -> Void,
         savePhoto: @escaping (UIImage, LabelAnnotation?, DataType) -> Void) {
        self.state = state
        self.dismiss = dismiss
        self.savePhoto = savePhoto
        _selectedLabel = State(initialValue: state.selectedLabel)
    }

    var body: some View {
        VStack {
            PredictionSummaryNavigationView(canSave: canSave, dismiss: dismiss, saveImage: saveImage)
            SummarySectionView(state: state)
            HStack(alignment: .top) {
                imageSection
                    .padding(.trailing, 10)
                ScrollView(.vertical) {
                    PredictionResultChart(data: state.observations, maxHeight: 200.0)
                        .chartFormRounded
                }
                .cornerRadius(10)
            }
            .frame(maxHeight: CGFloat(.barchart.maxEvalChartHeight))
            .padding(.horizontal, 15)
            .padding(.vertical, 10)

            Form {
                LabelCorrectionView(observations: state.observations, currentLabels: state.currentLabels, selectedLabel: $selectedLabel)
                DataSavingView(selectedLocation: $saveDestination)
            }
            .scrollContentBackground(.hidden)

            Spacer()

        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }

    private var canSave: Bool {
        !state.currentLabels.isEmpty
    }

    private var imageSection: some View {
        Image(uiImage: state.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    private func saveImage() {
        savePhoto(state.image, selectedLabel, saveDestination)
        dismiss() // close view
    }
}

extension View {
    var chartFormRounded: some View {
        self
            .background(in: RoundedRectangle(cornerRadius: 10))
            .backgroundStyle(Color(UIColor.tertiarySystemBackground))
    }
}

// MARK: - Previews

#if DEBUG

#Preview("4 labels") {
    PredictionSummaryView.fake(state: .fake)
}

#Preview("7 labels") {
    PredictionSummaryView.fake(state: .fakeLargeState)
}

#Preview("2 labels") {
    PredictionSummaryView.fake(state: .fakeSmallState)
}

extension PredictionSummaryView {
    static func fake(state: PredictionSummaryViewState) -> Self {
        .init(
            state: state,
            dismiss: {
                print("Dismiss")
            },
            savePhoto: { image, annotation, type in
                print("Save photo \(image), annotation? \(String(describing: annotation)), type \(type)")
            }
        )
    }
}

#endif
