// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import os.log

actor ClassificationImageStreamer {
    static let processingThreshold = 20

    private let projectID: ProjectID
    private let validationRepository: ValidationRepository
    private let photoSizer: PhotoSizer
    private var frameCounter = 0

    private(set) var sendImage: @Sendable (UIImage) -> Void = { _ in
        // This function is no-op when the stream is closed and we don't open the stream until it's needed.
    }
    private(set) var finishSendingImages: @Sendable () -> Void = {
        os_log(.error, "finishSendingImages not initialized")
    }

    init(projectID: ProjectID, validationRepository: ValidationRepository, photoSizer: PhotoSizer) {
        self.projectID = projectID
        self.validationRepository = validationRepository
        self.photoSizer = photoSizer
    }

    deinit {
        finishSendingImages()
    }

    func liveObservationsFromCamera() -> AsyncStream<CameraPredictionOverlayState> {

        AsyncStream { continuation in
            self.finishSendingImages = {
                continuation.finish()
                os_log(.info, "Terminated live observation stream")
            }
            self.sendImage = { [weak self] image in
                if Task.isCancelled {
                    continuation.finish()
                }
                Task { [weak self] in
                    guard let self else {
                        return
                    }
                    guard await shouldYieldImageWithCurrentFrame() else {
                        return
                    }
                    if let predictionOverlayState = await self.process(image: image) {
                        continuation.yield(predictionOverlayState)
                    }
                }
            }
        }
    }

    private func shouldYieldImageWithCurrentFrame() -> Bool {
        let shouldYield = frameCounter == 0
        frameCounter = (frameCounter + 1) % Self.processingThreshold
        return shouldYield
    }

    private func process(image: UIImage) async -> CameraPredictionOverlayState? {
        do {
            let sizedImage = photoSizer.scaleAndCrop(image: image)
            let predictionOverlayState = try await observation(from: sizedImage)
            return predictionOverlayState
        } catch {
            os_log(.error, "Failed to classify image from camera: \(error)")
        }
        return nil
    }

    private func observation(from image: UIImage) async throws -> CameraPredictionOverlayState {
        let labelID = LabelID(id: UUID(), projectID: projectID)
        let labeledImage = LabeledImage(image: image, labelID: labelID)
        return try await validationRepository.classify(labeledImage: labeledImage).observations
    }
}
