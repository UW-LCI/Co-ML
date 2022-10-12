// Copyright 2026 Apple Inc. All rights reserved.

import AVFoundation
import os.log
import CoreImage
import UIKit

extension CameraCaptureSession {
    func setupLiveVideoOutput(captureSession: AVCaptureSession, videoOutput: AVCaptureVideoDataOutput, videoOutputQueue: DispatchQueue) {
        guard captureSession.canAddOutput(videoOutput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(videoOutput)

        let pixelBufferFormatKey = Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelBufferFormatKey
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.connection(with: .video)?.isEnabled = true // Always process the frames
    }
}

extension CameraCaptureSession: AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        let image = UIImage(buffer: sampleBuffer)
        Task {
            await classificationLiveImageStreamer.sendImage(image)
        }
    }
}

private extension UIImage {
    convenience init(buffer: CMSampleBuffer) {
        let imageBuffer = CMSampleBufferGetImageBuffer(buffer)!
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        self.init(ciImage: ciimage)
    }

    convenience init(ciImage: CIImage) {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
        self.init(cgImage: cgImage)
    }
}
