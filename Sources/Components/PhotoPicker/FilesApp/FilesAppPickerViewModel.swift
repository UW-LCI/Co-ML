// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI
import os.log

struct FilesAppPickerViewModel {
    let preprocessPhoto: (UIImage) -> UIImage
    let importPhotos: ([UIImage]) -> Void

    func importFiles(result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            do {
                let images = try fileToScaledImage(files)
                importPhotos(images)
            } catch let error {
                os_log(.error, "Failed to import photos from Files app URLs \(error)")
            }
        case .failure(let error):
            os_log(.error, "An error occurred in the Files app \(error)")
        }
    }

    private func fileToScaledImage(_ fileList: [URL]) throws -> [UIImage] {
        var scaledImageList: [UIImage] = []

        for fileURL in fileList {
            let scaledImage = try accessImage(fileURL)
            scaledImageList.append(scaledImage)
        }

        return scaledImageList
    }

    private func accessImage(_ fileURL: URL) throws -> UIImage {
        // ensure we stop accessing fileURL before we leave this function
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }

        // check if we can access the file securely
        guard fileURL.startAccessingSecurityScopedResource() else {
            os_log(.error, "Unable to access secure scoped URL \(fileURL.path)")
            throw FileAppPickerError.cannotAccessFileURLs
        }

        // convert the file to image data
        guard let rawImage = UIImage(contentsOfFile: fileURL.path) else {
            os_log(.error, "Unable to convert URL to UIImage for path \(fileURL.path)")
            throw FileAppPickerError.cannotOpenFileAsImage
        }

        // preprocess photo
        return preprocessPhoto(rawImage)
    }
}

enum FileAppPickerError: Error {
    case cannotAccessFileURLs
    case cannotOpenFileAsImage
}
