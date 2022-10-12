// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import SwiftUI

// Shows the camera preview and a stacked list of captured images on the left hand side
struct CameraView: View {

    @Environment(\.dismiss) var dismiss // built-in SwiftUI function to return to previous screen

    @StateObject private var viewModel: CameraViewModel
    let imageSelected: (LabeledImageID) -> Void

    init(cameraSettings: CameraSettings,
         projectID: ProjectID,
         projectModelInfoRepository: ProjectModelInfoRepository,
         imageFetchRepository: ImageFetchRepository,
         imageRepository: ImageRepository,
         modelStorageService: ModelStorageService,
         imageSelected: @escaping (LabeledImageID) -> Void
    ) {
        self.imageSelected = imageSelected
        _viewModel = StateObject(wrappedValue: {
            let validationRepository = ValidationRepositoryImpl(projectID: projectID, urlGenerator: URLGeneratorImpl(projectID: projectID))
            let wrappedAddImagesModel = CameraViewModel(projectID: projectID,
                                                        cameraSettings: cameraSettings,
                                                        projectModelInfoRepository: projectModelInfoRepository,
                                                        imageFetchRepository: imageFetchRepository,
                                                        imageRepository: imageRepository,
                                                        validationRepository: validationRepository,
                                                        modelStorageService: modelStorageService)
            return wrappedAddImagesModel
        }() )
    }

    var body: some View {
        ZStack {
            // The live camera layer is in here
            CameraFeedView(
                imageStreamer: viewModel.imageStreamer,
                classificationImageStreamer: viewModel.classificationImageStreamer
            )

            // camera mode toggle
            if viewModel.hasModel {
                VStack {
                    Spacer()
                    CameraModeToggle(mode: $viewModel.cameraMode)
                }
            }

            switch viewModel.cameraMode {
            case .collectionMode:
                CollectionCameraView(viewModel: viewModel.collectionViewModel, showImageAction: imageSelected)
            case .classificationMode:
                ClassificationCameraView(viewModel: viewModel.classifyViewModel)
            }
        }
        .preferredColorScheme(.dark) // keeps camera UI dark
        .navigationBarBackButtonHidden() // hide to replace with custom toolbar
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(.done) {
                    dismiss() // return to prior screen
                }
            }
        }
        .task {
            // Check if there is a model
            await viewModel.checkForModel()
        }
        .task {
            // start the camera
            await viewModel.listenForCameraImages()
        }
    }
}
