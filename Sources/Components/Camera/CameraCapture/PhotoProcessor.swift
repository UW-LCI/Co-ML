// Copyright 2026 Apple Inc. All rights reserved.

import AVFoundation
import Foundation
import os.log
import UIKit

final class PhotoProcessor: NSObject, AVCapturePhotoCaptureDelegate {

    let onImageProcessed: (UIImage) -> Void
    let photoSizer: PhotoSizer
    private var lastKnownOrientation: UIImage.Orientation?

    init(photoSizer: PhotoSizer, onImageProcessed: @escaping (UIImage) -> Void) {
        self.onImageProcessed = onImageProcessed
        self.photoSizer = photoSizer
    }

    // Comment ported from Co-ML: https://stackoverflow.com/a/46896096/1720985
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            os_log(.error, "Error generating image data: \(error)")
            return
        }

        guard let image = UIImage(data: imageData) else {
            os_log(.error, "Error generating image: %@", error?.localizedDescription ?? "-")
            return
        }

        let resizedImage = photoSizer.scaleAndCrop(image: image)
        let orientedImage = orientedImage(from: resizedImage)

        onImageProcessed(orientedImage)
    }

    func updateVideoOrientation(to orientation: AVCaptureVideoOrientation) {
        guard let orientation = UIImage.Orientation(withLandscapeRestricted: orientation) else {
            os_log(.error, "Unexpected AVCapture orientation \(orientation.rawValue)")
            return
        }
        os_log(.debug, "setting last known orientation to \(orientation.rawValue)")
        lastKnownOrientation = orientation
    }

    // MARK: - Private

    /// Returns an oriented image based on the current device orientation. Falls back to input image.
    private func orientedImage(from image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        let orientation: UIImage.Orientation
        if let lastKnownOrientation {
            orientation = lastKnownOrientation
        } else {
            os_log(.debug, "No last known orientation so defaulting to .right")
            orientation = .right
        }
        os_log(.debug, "oriented image orientation \(orientation.rawValue)")
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}

extension UIImage.Orientation {
    init?(withLandscapeRestricted orientation: AVCaptureVideoOrientation) {
        switch orientation {
        case .portrait:
            return nil
        case .portraitUpsideDown:
            return nil
        case .landscapeRight:
            self = .left
        case .landscapeLeft:
            self = .right
        @unknown default:
            return nil
        }
    }
}
