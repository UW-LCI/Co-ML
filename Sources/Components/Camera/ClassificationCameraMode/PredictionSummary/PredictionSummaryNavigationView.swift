// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct PredictionSummaryNavigationView: View {

    let canSave: Bool
    let dismiss: () -> Void
    let saveImage: () -> Void

    var body: some View {
        HStack {
            topCancelButton
            Spacer()
            titleSection
            Spacer()
            topSaveButton
        }
        .padding(15)
    }

    // MARK: - Private

    private var topCancelButton: some View {
        Button {
            dismiss()
        } label: {
            Label(cancelButtonTitle, systemImage: "x.circle")
                .labelStyle(.titleOnly)
                .foregroundColor(.blue)
        }
    }

    private var titleSection: some View {
        Label(confirmLabelTitle, systemImage: "checkmark")
            .labelStyle(.titleOnly)
            .fontWeight(.bold)
    }

    private var topSaveButton: some View {
        Button(saveButtonTitle) {
            saveImage()
        }.disabled(!canSave)
    }

    private var cancelButtonTitle: String {
        String(localized: .cancel)
    }

    private var confirmLabelTitle: String {
        String(localized: .confirmLabel)
    }

    private var saveButtonTitle: String {
        String(localized: .save)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    PredictionSummaryNavigationView(canSave: true) {
        print("Cancel")
    } saveImage: {
        print("Save")
    }
}

#endif
