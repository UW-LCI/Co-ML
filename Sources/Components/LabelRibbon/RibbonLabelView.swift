// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

/// The Label editor for each row in the ribbon : show, rename and delete labels
struct RibbonLabelView: View {

    let label: LabelAnnotation

    let action: (GridViewAction) -> Void

    /// Control and check if the label is being edited
    @FocusState private var editFocus: Bool

    var body: some View {
        HStack {
            labelField
            Menu(content: actionButtons) {
                menuLabel
            }
        }
        .accessibilityActions(actionButtons)
    }

    var labelField: some View {
        SubmitTextField(label: label.labelString, isFocused: editFocus) { newLabel in
            action(.rename(label, to: newLabel))
        }
        .multilineTextAlignment(.leading) // the text defaults to center align without this property
        .focused($editFocus)
        .fixedSize(horizontal: true, vertical: false) // Shrink to fit label
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // Delete this label
    private func deleteAction() {
        action(.delete(label))
    }

    // Switch to renaming mode
    private func renameAction() {
        editFocus = true
    }

    private var menuLabel: some View {
        Label(.labelMenu, systemImage: "ellipsis.circle")
            .labelStyle(.iconOnly)
            .padding(10)
            .contentShape(Rectangle())
            .accessibilityIdentifier("\(label.labelString) menu label")
    }

    /// Action buttons: used by menu and accessibility
    @ViewBuilder
    private func actionButtons() -> some View {
        Button(action: renameAction) {
            Label(.rename, systemImage: "tag")
        }
        .accessibilityIdentifier("\(label.labelString) rename button")

        Button(role: .destructive, action: deleteAction) {
            Label(.delete, systemImage: "trash")
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NavigationStack {
        List {
            RibbonLabelView(label: .fakeAppleLabel) {
                print("Apple action: '\($0)'.")
            }
            RibbonLabelView(label: .fakeBananaLabel) {
                print("Banana action: '\($0)'.")
            }
            RibbonLabelView(label: .fakeCarrotLabel) {
                print("Carrot action: '\($0)'.")
            }
            Spacer()
        }.listStyle(.plain)
    }
}

#endif
