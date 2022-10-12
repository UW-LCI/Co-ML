// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit
import os.log

final class PhotoSizerImpl: PhotoSizer {
    private enum Constants {
        // Ported from Co-ML (with original comment: "scale down image size for storing on CloudKit")
        static let imageSize = 299.0
    }

    /// When `true`, this photo sizer will always re-rasterize an image, even if the scale is as expected. This is to
    /// ensure proper orientation in certain image processing pipelines.
    private let alwaysRasterize: Bool

    init(alwaysRasterize: Bool = false) {
        self.alwaysRasterize = alwaysRasterize
    }

    func scaleAndCrop(image: UIImage) -> UIImage {
        os_log(.debug, "Scaling and cropping photo taken by user")
        let uiImageResized = Self.scaleAndCrop(image: image,
                                               toSize: .init(width: Constants.imageSize,
                                                             height: Constants.imageSize),
                                               alwaysRasterize: alwaysRasterize)
        return uiImageResized
    }

    // Ported from Co-ML with some minor code changes:
    //
    // from https://gist.github.com/jkereako/200342b66b5416fd715a
    private static func scaleAndCrop(image: UIImage,
                                     toSize desiredSize: CGSize,
                                     alwaysRasterize: Bool
    ) -> UIImage {
        // Make sure the image isn't already sized.
        if !alwaysRasterize && image.size.equalTo(desiredSize) {
            return image
        }
        let widthFactor = desiredSize.width / image.size.width
        let heightFactor = desiredSize.height / image.size.height
        let scaleFactor: CGFloat = widthFactor > heightFactor ? widthFactor : heightFactor

        var thumbnailOrigin = CGPoint.zero
        let scaledWidth  = image.size.width * scaleFactor
        let scaledHeight = image.size.height * scaleFactor
        if widthFactor > heightFactor {
            thumbnailOrigin.y = (desiredSize.height - scaledHeight) / 2.0
        } else if widthFactor < heightFactor {
            thumbnailOrigin.x = (desiredSize.width - scaledWidth) / 2.0
        }

        var thumbnailRect = CGRect.zero
        thumbnailRect.origin = thumbnailOrigin
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight

        // We don't support partially-transparent images, and we want our scale to be 1.0.
        let imageRendererFormat = UIGraphicsImageRendererFormat()
        imageRendererFormat.opaque = true
        imageRendererFormat.scale = 1.0

        let imageRenderer = UIGraphicsImageRenderer(size: desiredSize, format: imageRendererFormat)
        let scaledImage = imageRenderer.image { _ in
            image.draw(in: thumbnailRect)
        }

        return scaledImage
    }
}

private extension UIDeviceOrientation {
    var imageOrientation: UIImage.Orientation {
        switch self {
        case .portrait, .faceUp:
            return .right
        case .portraitUpsideDown, .faceDown:
            return .left
        case .landscapeLeft:
            return .up // this is the base orientation
        case .landscapeRight:
            return .down
        case .unknown:
            return .up
        @unknown default:
            fatalError("Unknown UIDeviceOrientation")
        }
    }
}
