// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// A view that allows the user to select a label annotation from a list.
/// - When a label is selected, a closure is invoked.
/// - Then, the parent view is expected to replace this view with a new one displaying the updated label selection.
struct SampleDetailLabelSelectionView: View {
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

        List {
            Picker(.label, selection: labelSelectionBinding) {
                ForEach(labels) { label in
                    Text(label.labelString).tag(label.id)
                }
            }
            .listRowBackground(Color(uiColor: .systemBackground))
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    SampleDetailLabelSelectionView(
        labels: .fakeLabels,
        selectedLabelID: .fakeAppleLabelID,
        onLabelSelected: {
            print("Selected label with ID '\($0)'.")
        }
    )
}

#endif
