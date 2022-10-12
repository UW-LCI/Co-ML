// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// A view that allows the user to select a label annotation from a list.
/// - When a label is selected, a closure is invoked.
/// - Then, the parent view is expected to replace this view with a new one displaying the updated label selection.
struct EvaluationLabelSelectionView: View {
    let labels: [LabelAnnotation]
    let selectedLabelID: LabelID
    let onLabelSelected: (LabelID) -> Void

    var body: some View {

        let labelSelectionBinding = Binding {
            self.selectedLabelID
        } set: {
            // When we call this, the parent view replaces us with a different view.
            onLabelSelected($0)
        }

        LabeledContent {
            Picker(.labelTableHeading, selection: labelSelectionBinding) {
                ForEach(labels) { label in
                    Text(label.labelString).tag(label.id)
                }
            }
        } label: {
            Text(.changeLabel)
                .padding()
        }
        .background(.background)
        .cornerRadius(10)
    }
}

// MARK: - Previews

#if DEBUG

#Preview(traits: .fixedLayout(width: 300, height: 200)) {
    EvaluationLabelSelectionView(
        labels: .fakeLabels,
        selectedLabelID: .fakeAppleLabelID,
        onLabelSelected: {
            print("Label selected: '\($0)'.")
        }
    )
    .frame(width: 300, height: 200)
}

#endif
