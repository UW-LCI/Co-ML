// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct LabelDetailView: View {
    @StateObject private var viewModel: LabelDetailViewModel
    let cameraRoute: ProjectFullScreenRoute
    let gridViewAction: (GridViewAction) -> Void

    init(labelAnnotation: LabelAnnotation,
         dataType: DataType,
         projectID: ProjectID,
         imageStorageService: ImageStorageService,
         labelDetailRepository: LabelDetailRepository,
         imageFetchRepository: ImageFetchRepository,
         databaseStorageService: DatabaseStorageService,
         gridViewAction: @escaping (GridViewAction) -> Void) {
        self.cameraRoute = LabelDetailViewModel.cameraRoute(label: labelAnnotation, dataType: dataType)
        self.gridViewAction = gridViewAction

        _viewModel = StateObject(wrappedValue: {
            LabelDetailViewModel(labelAnnotation: labelAnnotation,
                                 dataType: dataType,
                                 projectID: projectID,
                                 imageStorageService: imageStorageService,
                                 labelDetailRepository: labelDetailRepository,
                                 imageFetchRepository: imageFetchRepository,
                                 databaseStorageService: databaseStorageService,
                                 openPhotosPicker: { settings in
                                     gridViewAction(.photosAppImport(to: settings.label))
                                 },
                                 openSampleDetail: { imageID in
                                     gridViewAction(.showImage(id: imageID))
                                 }
            )
        }())
    }

    var body: some View {
        LabelDetailInnerView(
            imageIDs: viewModel.imageIDs,
            imageCount: viewModel.imageCount,
            purposeString: viewModel.dataType.purposeString,
            cameraRoute: cameraRoute,
            labelExists: viewModel.labelExists,
            labelString: viewModel.labelAnnotation.labelString,
            fetchImage: viewModel.fetchImage,
            openPhotosPicker: viewModel.openPhotosPicker,
            openSampleDetail: viewModel.openSampleDetail,
            updateLabel: viewModel.update(label:),
            deleteImage: { imageID in
                gridViewAction(.deleteImage(imageID))
            }
        )
        .task {
            await viewModel.monitorProjectChanges()
        }
    }
}

private struct LabelDetailInnerView: View {
    let imageIDs: [LabeledImageID]
    let imageCount: Int
    let purposeString: String
    let cameraRoute: ProjectFullScreenRoute
    let labelExists: Bool
    let labelString: String
    let fetchImage: (UUID) async throws -> UIImage
    let openPhotosPicker: () -> Void
    let openSampleDetail: (LabeledImageID) -> Void
    let updateLabel: (String) -> Void
    let deleteImage: (LabeledImageID) -> Void

    var body: some View {
        if labelExists {
            LabelDetailMainView(imageIDs: imageIDs,
                               imageCount: imageCount,
                               purposeString: purposeString,
                               cameraRoute: cameraRoute,
                               labelString: labelString,
                               fetchImage: fetchImage,
                               openPhotosPicker: openPhotosPicker,
                               openSampleDetail: openSampleDetail,
                               updateLabel: updateLabel,
                               deleteImage: deleteImage)
        } else {
            LabelDisappearedView(lastKnownLabelTitle: labelString,
                                      lastKnownImageCount: imageCount,
                                      purposeString: purposeString)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Static") {
    LabelDetailInnerPreviewView(
        imageIDs: [ .fakeApple1id, .fakeApple2id, .fakeApple3id, .fakeApple4id ],
        labelExists: true
    )
}

#Preview("Label disappeared") {
    LabelDetailInnerPreviewView(
        imageIDs: [ .fakeApple1id, .fakeApple2id, .fakeApple3id, .fakeApple4id ],
        labelExists: false
    )
}

struct LabelDetailInnerPreviewView: View {
    var imageIDs: [LabeledImageID]
    var labelExists: Bool

    @Namespace private var imageNamespace
    var body: some View {
        NavigationStack {
            LabelDetailInnerView(
                imageIDs: imageIDs,
                imageCount: imageIDs.count,
                purposeString: "test",
                cameraRoute: .labelDetailPage(
                    projectID: ProjectID(),
                    labelAnnotation: .fakeAppleLabel,
                    dataType: .training,
                    imageNamespace: imageNamespace
                ),
                labelExists: labelExists,
                labelString: .fakeAppleLabelString,
                fetchImage: ImageFetchRepositoryFake.fetchImage,
                openPhotosPicker: {
                    print("openPhotosPicker")
                },
                openSampleDetail: { imageID in
                    print("openSampleDetail \(imageID)")
                },
                updateLabel: { labelString in
                    print("update label to \(labelString)")
                },
                deleteImage: { imageID in
                    print("delete image \(imageID)")
                }
            )
        }
    }
}

#endif
