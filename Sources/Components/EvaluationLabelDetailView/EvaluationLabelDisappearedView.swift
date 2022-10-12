// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationLabelDisappearedView: View {
    let lastKnownLabelTitle: String
    let lastKnownImageCount: Int

    @State private var isShowingLabelDeletedAlert = true

    var body: some View {
        VStack(alignment: .leading) {
            TextField(String(localized: .label), text: .constant(lastKnownLabelTitle))
                .disabled(true)
                .font(.title2.bold())

            VStack(alignment: .leading) {
                Text(.imageCountSubtitle(lastKnownImageCount))
            }
            .font(.subheadline)
            .foregroundColor(Color(uiColor: .secondaryLabel))

            Spacer()
        }
        .padding()
        .toolbar {
            toolbarItems
        }
        .alert(isPresented: $isShowingLabelDeletedAlert) {
            Alert(
                title: Text(.hasBeenDeleted(lastKnownLabelTitle)),
                message: Text(.thisLabelNoLongerExists),
                dismissButton: .default(Text(.ok)) {
                    isShowingLabelDeletedAlert = false
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(.testImages)
                .font(.headline)
        }
        ToolbarItem {
            NavigationLink(value: ProjectFullScreenRoute?.none) {
                Label(.openCamera, systemImage: "camera.fill")
            }
            .disabled(true)
        }
        ToolbarItem {
            Button {
                // No-op
            } label: {
                Label(.openPhotoAlbum, systemImage: "photo")
            }
            .disabled(true)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NavigationStack {
        EvaluationLabelDisappearedView(
            lastKnownLabelTitle: "Apples",
            lastKnownImageCount: 35
        )
    }
}

#endif
