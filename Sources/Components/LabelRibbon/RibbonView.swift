// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// A generic ribbon view to display LabelRibbonViewState
struct RibbonView<CardView: View>: View {

    let viewModel: LabelRibbonViewState
    let fetchImage: (UUID) async throws -> UIImage
    let action: (GridViewAction) -> Void
    let openLabel: ProjectFullScreenRoute
    let openCamera: ProjectFullScreenRoute
    let cardView: (LabeledImageID) -> CardView

    var body: some View {
        VStack(alignment: .leading) {
            titleBar
                .padding(.horizontal)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: .tile.spacing) {
                    ForEach(viewModel.imageIDs) { imageID in
                        cardView(imageID)
                    }
                    if viewModel.imageList.count > 10 {
                        SeeImagesScrollButton(navigationLink: openLabel, labelName: viewModel.label.labelString)
                    }
                }
                .padding(.bottom)
                .padding(.horizontal)
            }
            .padding(.top, 5)
            Divider()
        }
    }

    private var titleBar: some View {
        HStack(alignment: .firstTextBaseline) {
            RibbonLabelView(label: viewModel.label, action: action)
            Spacer()
            SeeImagesButton(label: viewModel.label, imageCount: viewModel.imageCount,
                            navigationLink: openLabel)
            AddImagesButton(openCameraLink: openCamera) {
                action(.photosAppImport(to: viewModel.label))
            } filesAppImport: {
                action(.filesAppImport(to: viewModel.label))
            }
            /// To make the button a little easier to tap
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    RibbonViewPreviewView(state: .fakeApples)
}

struct RibbonViewPreviewView: View {
    var state: LabelRibbonViewState

    @Namespace private var imageNamespace

    var body: some View {
        RibbonView(
            viewModel: state,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            action: {
                print("Action: '\($0)'.")
            },
            openLabel: .labelDetailPage(
                projectID: ProjectID(),
                labelAnnotation: .fakeAppleLabel,
                dataType: .testing,
                imageNamespace: imageNamespace
            ),
            openCamera: .cameraPage(
                projectID: ProjectID(),
                settings: .default
            ),
            cardView: { imageID in
                SampleImageView {
                    try await ImageFetchRepositoryFake.fetchImage(imageID.sampleID)
                }
                .frame(width: 40, height: 40)
            }
        )
    }
}

#endif
