// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct LabelDisappearedView: View {
    private struct GridCardIndex: Identifiable, Hashable {
        let index: Int
        init(_ index: Int) {
            self.index = index
        }
        // MARK: - Identifiable
        var id: Int { index }
    }

    let lastKnownLabelTitle: String
    let lastKnownImageCount: Int
    let purposeString: String

    @State private var isShowingLabelDeletedAlert = true

    var body: some View {
        LabelDetailInnerGridView(
            gridCardStates: gridCardIndices,
            purposeString: purposeString,
            subtitleText: {
                Text(.imageCountSubtitle(lastKnownImageCount))
                .redacted(reason: .placeholder)
            },
            gridCard: { index in
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .redacted(reason: .placeholder)
                    .id(index)
            },
            titleView: {
                TextField(String(localized: .label), text: .constant(lastKnownLabelTitle))
                    .disabled(true)
            },
            toolbarCameraButton: {
                NavigationLink(value: ProjectFullScreenRoute?.none) {
                    Label(.openCamera, systemImage: "camera.fill")
                }
                .disabled(true)
            },
            toolbarPhotoAlbumButton: {
                Button {
                    // No-op
                } label: {
                    Label(.openPhotoAlbum, systemImage: "photo")
                }
                .disabled(true)
            }
        )
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

    private var gridCardIndices: [GridCardIndex] {
        Array(0..<lastKnownImageCount).map { GridCardIndex($0) }
    }
}
