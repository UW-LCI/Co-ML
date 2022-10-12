// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI
import os.log

struct CollectionCameraView: View {

    @ObservedObject var viewModel: CollectionCameraViewModel
    let showImageAction: (LabeledImageID) -> Void

    var body: some View {
        CameraUIContent(leftMarginContents:
                            CameraRecentPhotosStream(
                                label: viewModel.labelString,
                                imageIDs: viewModel.imageIDs,
                                fetchImage: viewModel.fetchImage,
                                showImageAction: showImageAction
                            ),
                        cameraOverlayContents: CameraLabelOverlay(
                            labelString: viewModel.labelString
                        ),
                        aboveShutterControls:
                            CameraTrainTestButtons(
                                dataType: $viewModel.settings.saveDestination
                            ),
                        belowShutterControls: CameraLabelPicker(
                            selection: $viewModel.settings.annotation,
                            labels: viewModel.annotationList
                        )
        )
        .alert(viewModel.errorAlertText, isPresented: $viewModel.showErrorAlert) {
            Button(.ok, role: .cancel) {
                viewModel.showErrorAlert = false
            }
        }
        // If the destination (label + dataType) changes, reload
        .task(id: viewModel.settings) {
            await viewModel.refreshImagesFromDatabase()
        }
        // first parallel task watched database for updates
        .task {
            await viewModel.observeDatabaseUpdates()
        }
        // another parallel task to load labels and image sidebar
        .task {
            do {
                try await viewModel.loadLabels()
                await viewModel.refreshImagesFromDatabase()
            } catch let error {
                os_log(.error, "Failed to initialize camera due to an error loading in this project's labels", error.localizedDescription)
            }
        }
    }

}
