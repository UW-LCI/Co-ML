// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct LabelDetailMainView: View {
    @FocusState private var isLabelTitleFocused: Bool

    let imageIDs: [LabeledImageID]
    let imageCount: Int
    let purposeString: String
    let cameraRoute: ProjectFullScreenRoute
    let labelString: String
    let fetchImage: (UUID) async throws -> UIImage
    let openPhotosPicker: () -> Void
    let openSampleDetail: (LabeledImageID) -> Void
    let updateLabel: (String) -> Void
    let deleteImage: (LabeledImageID) -> Void

    var body: some View {
        LabelDetailInnerGridView(
            gridCardStates: imageIDs,
            purposeString: purposeString,
            subtitleText: {
                VStack(alignment: .leading) {
                    Text(.imageCountSubtitle(imageCount))
                }
            },
            gridCard: { imageID in
                gridItem(imageID: imageID)
            },
            titleView: {
                SubmitTextField(
                    label: labelString,
                    isFocused: isLabelTitleFocused,
                    submit: { updateLabel($0) }
                )
            },
            toolbarCameraButton: {
                NavigationLink(value: cameraRoute) {
                    Label(.openCamera, systemImage: "camera.fill")
                }
            },
            toolbarPhotoAlbumButton: {
                Button {
                    openPhotosPicker()
                } label: {
                    Label(.openPhotoAlbum, systemImage: "photo")
                }
            }
        )
    }

    func gridItem(imageID: LabeledImageID) -> some View {
        Button {
            openSampleDetail(imageID)
        } label: {
            SampleImageView {
                try await fetchImage(imageID.sampleID)
            }
            .aspectRatio(1, contentMode: .fill)
        }
        .modifier(DeleteImageContextMenu(action: {
            deleteImage(imageID)
        }))
    }
}
