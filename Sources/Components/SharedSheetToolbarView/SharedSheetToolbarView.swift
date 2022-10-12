// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct SharedSheetToolbarView: View {

    let localizedTitle: String
    let deleteButtonAction: () -> Void
    let doneButtonAction: () -> Void
    let moveAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            deleteButton
            moveButtonIfNeeded
            Spacer()
            titleView
            Spacer()
            doneButton
        }
        .background(.background)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteButtonAction()
        } label: {
            Label(.deleteImage, systemImage: "trash")
                .labelStyle(.iconOnly)
                .padding(.modal.toolbarPadding)
                .contentShape(Rectangle())
        }
        .keyboardShortcut(.delete)
    }

    @ViewBuilder
    private var moveButtonIfNeeded: some View {
        if let moveAction {
            Button {
                moveAction()
            } label: {
                Label(.moveImage, systemImage: "folder")
                    .labelStyle(.iconOnly)
                    .padding(.modal.toolbarPadding)
                    .contentShape(Rectangle())
            }
        }
    }

    private var titleView: some View {
        Text(localizedTitle)
            .accessibilityLabel(.labelForImage)
            .accessibilityValue(localizedTitle)
            .font(.headline)
    }

    private var doneButton: some View {
        Button {
            doneButtonAction()
        } label: {
            Text(.done)
                .padding(.modal.toolbarPadding)
                .contentShape(Rectangle())
        }
        .keyboardShortcut(.defaultAction)
    }
}

// MARK: - Previews

#if DEBUG

#Preview(traits: .fixedLayout(width: 400, height: 300)) {
    ZStack {
        Spacer()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray)
        VStack {
            SharedSheetToolbarView(
                localizedTitle: "Banana",
                deleteButtonAction: {
                    print("Delete button tapped")
                },
                doneButtonAction: {
                    print("Done button tapped")
                },
                moveAction: {
                    print("Move tapped")
                }
            )
            Spacer()
        }
    }
}

#endif
