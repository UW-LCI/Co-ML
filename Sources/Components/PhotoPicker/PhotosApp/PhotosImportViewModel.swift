// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import PhotosUI
import CoreTransferable
import os.log

@MainActor
class PhotosImportViewModel: ObservableObject {
    let preprocessPhoto: (UIImage) -> UIImage
    let importPhotos: ([UIImage]) -> Void

    @Published var imageSelection: [PhotosPickerItem] = [] {
        didSet {
            if imageSelection.isEmpty == false {
                // load the user's selected items
                loadTransferable(from: imageSelection)
            }
        }
    }

    init(preprocessPhoto: @escaping (UIImage) -> UIImage, importPhotos: @escaping ([UIImage]) -> Void) {
        self.preprocessPhoto = preprocessPhoto
        self.importPhotos = importPhotos
    }

    // MARK: - Private Methods

    private func clearSelection() {
        imageSelection = []
    }

    private func loadTransferable(from selectedItems: [PhotosPickerItem]) {
        Task {
            os_log(.info, "Starting import of \(selectedItems.count) photo picker items.")
            for photoPickerItem in selectedItems {
                photoPickerItem.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data?):
                        // Handle the success case with the image.
                        if let image = try? self.dataToImage(data) {
                            // import whatever photos we succeeded with
                            self.importPhotos([image])
                        } else {
                            os_log(.error, "Failed to import a photo \(photoPickerItem.itemIdentifier ?? "n/a"): Failed to convert to UIImage")
                        }
                    case .success(nil):
                        os_log(.error, "Failed to import a photo \(photoPickerItem.itemIdentifier ?? "n/a"): Photo data is empty")
                    case .failure(let error):
                        os_log(.error, "Failed to import a photo \(photoPickerItem.itemIdentifier ?? "n/a") with error \(error)")
                    }
                }
            }

            // clear selection for next time
            clearSelection()
        }
    }

    private func dataToImage(_ data: Data) throws -> UIImage {
        // check for valid image data
        guard let uiImage = UIImage(data: data) else {
            throw PhotoImportError.importFailed
        }

        return self.preprocessPhoto(uiImage)
    }

}
