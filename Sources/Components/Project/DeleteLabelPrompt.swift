// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct DeleteLabelPrompt: ViewModifier {

    @Binding var showDeleteAlert: Bool
    @Binding var askToDeleteLabel: LabelAnnotation?
    let deleteLabel: (LabelID) -> Void

    func body(content: Content) -> some View {
        content.alert(isPresented: $showDeleteAlert) {
            if let label = askToDeleteLabel {
                return Alert(
                    title: Text(.deleteLabel),
                    message: Text(.deleteLabelCautionaryAlertMessage(label.labelString)),
                    primaryButton: .destructive(Text(.delete)) {
                        // Handle the deletion.
                        deleteLabel(label.id)
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text(.deleteLabel),
                    message: Text(.somethingWentWrongDeletingThisLabelTryAgain)
                )
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    Text(verbatim: "Button")
        .modifier(
            DeleteLabelPrompt(
                showDeleteAlert: .constant(true),
                askToDeleteLabel: .constant(LabelAnnotation.fakeAppleLabel)
            ) {
                print("Confirm delete label '\($0)'.")
            }
        )
}

#endif
