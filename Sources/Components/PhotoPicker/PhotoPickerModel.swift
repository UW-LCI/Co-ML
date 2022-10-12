// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import SwiftUI

@MainActor
final class PhotoPickerModel {
    private let imageRepository: ImageRepository
    private let photoSizer: PhotoSizer

    init(projectID: ProjectID,
         imageStorageService: ImageStorageService,
         photoSizer: PhotoSizer) {
        self.photoSizer = photoSizer
        self.imageRepository = ImageRepositoryImpl(projectID: projectID, imageStorageService: imageStorageService)
    }

    func preprocessImage(rawImage: UIImage) -> UIImage {
        // size and crop image
        return photoSizer.scaleAndCrop(image: rawImage)
    }

    func saveToProject(_ scaledImages: [UIImage], saveSettings: PhotoPickerSettings) {
        // Spawn a task to handle the images we collected, in the background.
        Task {
            do {
                let labeledImages = scaledImages.map {
                    LabeledImage(image: $0,
                                 labelID: saveSettings.label.id,
                                 dataType: saveSettings.saveDestination)
                }
                try await imageRepository.add(labeledImages: labeledImages)
            } catch let error {
                os_log(.error, "Something went wrong adding picked photos to the dataset: \(error)")
            }
            os_log(.info, "Done listening for images the user takes in \(#fileID)")
        }
    }
}
