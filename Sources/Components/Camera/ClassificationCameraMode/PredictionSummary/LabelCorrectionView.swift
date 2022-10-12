// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct LabelCorrectionView: View {
    let observations: [Observation]
    let currentLabels: [LabelAnnotation]
    @Binding var selectedLabel: LabelAnnotation?

    var body: some View {
        Section {
            List {
                LabeledContent(modelPredictionTitle, value: observations.first!.annotation)
                if currentLabels.isEmpty {
                    noLabelWarning
                } else {
                    labelPicker
                }
            }
            .listRowBackground(Color(UIColor.tertiarySystemBackground))
        }
    }

    // MARK: - Private

    private var noLabelWarning: some View {
        LabeledContent(correctLabelTitle) {
            Text(.thisProjectHasNoLabels)
            .foregroundColor(.accentColor)
            .italic()
        }
    }

    private var labelPicker: some View {
        Picker(correctLabelTitle, selection: $selectedLabel) {
            ForEach(currentLabels) { label in
                Text(label.labelString).tag(_?(label))
            }
        }
    }

    private var modelPredictionTitle: String {
        String(localized: .modelPrediction)
    }

    private var correctLabelTitle: String {
        String(localized: .correctLabel)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    LabelCorrectionView(
        observations: .fakeObservationData,
        currentLabels: .fakeLabels,
        selectedLabel: .constant(.fakeCarrotLabel)
    )
}

extension [Observation] {
    static var fakeObservationData: Self {
        [
            .init(annotation: "Apple", confidence: 0.73),
            .init(annotation: "Strawberry", confidence: 0.2),
            .init(annotation: "Orange", confidence: 0.07),
            .init(annotation: "Banana", confidence: 0.0),
            .init(annotation: "Lemon", confidence: 0.0),
        ]
    }
}

#endif
