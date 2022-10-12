// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import UIKit
import SwiftUI

@MainActor
final class CameraViewModel: ObservableObject {

    @Published var cameraMode: CameraViewMode {
        didSet {
            os_log(.info, "Camera mode updated by user or otherwise: \(self.cameraMode)")
        }
    }
    @Published var hasModel: Bool = false

    // child view models
    let classifyViewModel: ClassificationCameraViewModel
    let collectionViewModel: CollectionCameraViewModel

    // data and services
    let imageStreamer: ScaledImageStreamer
    let classificationImageStreamer: ClassificationImageStreamer
    private let projectModelInfoRepository: ProjectModelInfoRepository
    private let imageFetchRepository: ImageFetchRepository
    private let imageRepository: ImageRepository
    private let modelStorageService: ModelStorageService
    private var existingImageIdentifiers: Set<String> = Set()

    init(projectID: ProjectID,
         cameraSettings: CameraSettings,
         projectModelInfoRepository: ProjectModelInfoRepository,
         imageFetchRepository: ImageFetchRepository,
         imageRepository: ImageRepository,
         validationRepository: ValidationRepository,
         modelStorageService: ModelStorageService) {

        self.modelStorageService = modelStorageService
        self.projectModelInfoRepository = projectModelInfoRepository
        self.imageFetchRepository = imageFetchRepository
        self.imageRepository = imageRepository

        self.imageStreamer = ScaledImageStreamer()

        // initialize camera mode
        self.cameraMode = cameraSettings.viewMode

        // set up classification live stream
        let photoSizer = PhotoSizerImpl()
        let classificationImageStreamer = ClassificationImageStreamer(projectID: projectID,
                                                                      validationRepository: validationRepository,
                                                                      photoSizer: photoSizer)
        self.classificationImageStreamer = classificationImageStreamer

        // set up view models
        self.classifyViewModel = ClassificationCameraViewModel(projectID: projectID,
                                                               classificationImageStreamer: classificationImageStreamer,
                                                               projectModelInfoRepository: projectModelInfoRepository,
                                                               imageRepository: imageRepository,
                                                               validationRepository: validationRepository,
                                                               modelStorageService: modelStorageService)

        self.collectionViewModel = CollectionCameraViewModel(settings: cameraSettings,
                                                             projectID: projectID,
                                                             projectModelInfoRepository: projectModelInfoRepository,
                                                             imageFetchRepository: imageFetchRepository,
                                                             imageRepository: imageRepository)
    }

    func checkForModel() async {
        let modelInfo = await modelStorageService.fetchModelInfo()
        hasModel = modelInfo != nil
    }

    func listenForCameraImages() async {
        os_log(.info, "Start listening for images the user takes in \(#fileID)")

        /// Each time the user presses the camera shutter button, a picture should arrive here
        for await image in await imageStreamer.imagesPickedByUser() {
            os_log(.info, "CameraViewModel received photo taken by user")
            if cameraMode == .collectionMode {
                await collectionViewModel.savePhoto(image: image)
            } else {
                await classifyViewModel.processPhotoTaken(image: image)
            }
        }
        os_log(.info, "Done listening for images the user takes in \(#fileID)")
    }
}

#if DEBUG

// creates fake CameraViewModel for view previews
extension CameraViewModel {
    static var fake: CameraViewModel {
        let projectID = ProjectID()
        let settings = CameraSettings(saveDestination: .training, viewMode: .collectionMode)
        return CameraViewModel(
            projectID: projectID,
            cameraSettings: settings,
            projectModelInfoRepository: ProjectModelInfoRepositoryFake(projectID: projectID),
            imageFetchRepository: ImageFetchRepositoryFake(),
            imageRepository: ImageRepositoryFake(projectID: projectID),
            validationRepository: ValidationRepositoryFake(projectID: projectID),
            modelStorageService: .fake()
        )
    }
}

#endif
