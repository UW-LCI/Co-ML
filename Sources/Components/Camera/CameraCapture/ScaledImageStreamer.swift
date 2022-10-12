// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit
import os.log

/// An image streamer that provides cropped/sized images.
struct ScaledImageStreamer: Sendable {

    let photoSizer: PhotoSizer = PhotoSizerImpl(alwaysRasterize: true)

    typealias OutSequence = AsyncMapSequence<AsyncStream<UIImage>, UIImage>

    /// Based on the implementation of a Subject - a streamer that does not transform
    private let subject = Subject<UIImage>()

    func sendImage(_ image: UIImage) async {
        await subject.send(image)
    }

    func imagesPickedByUser() async -> OutSequence {
        await subject.stream.map { image in
            return photoSizer.scaleAndCrop(image: image)
        }
    }
}
