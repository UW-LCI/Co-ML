// Copyright 2026 Apple Inc. All rights reserved.

import AVFoundation
import Foundation
import os.log
import UIKit

enum CameraCaptureSessionError: Error {
    case notAuthorized
}

// AVCaptureSession needs to be kicked off from a background thread, so this logic now
// lives in its own actor rather than a ViewController.
actor CameraCaptureSession: NSObject {
    private enum Constants {
        static let scaleFactor = 0.9
    }

    private let captureSession = AVCaptureSession()

    private var backCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?

    private let imageStreamer: ScaledImageStreamer
    private var photoProcessor: PhotoProcessor!
    private(set) var classificationLiveImageStreamer: ClassificationImageStreamer

    private lazy var videoOutput = AVCaptureVideoDataOutput()
    private lazy var videoOutputQueue = DispatchQueue(
        label: "VideoOutput",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    init(imageStreamer: ScaledImageStreamer, classificationImageStreamer: ClassificationImageStreamer) {
        self.imageStreamer = imageStreamer
        self.classificationLiveImageStreamer = classificationImageStreamer
        captureSession.sessionPreset = .photo
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: photoProcessor)
    }

    func setupCamera() throws {
        setupDevice()
        try setupDeviceInputAndOutput()
        startRunningCaptureSession()
        photoProcessor = PhotoProcessor(photoSizer: PhotoSizerImpl()) { [imageStreamer] image in
            Task { [imageStreamer] in
                await imageStreamer.sendImage(image)
            }
        }
    }

    func startRunningCaptureSession() {
        captureSession.startRunning()
    }

    func captureSession() async -> AVCaptureSession {
        captureSession
    }

    func updateVideoOrientation(to orientation: AVCaptureVideoOrientation) {
        photoProcessor.updateVideoOrientation(to: orientation)
    }

    private func removeSessionAndRestart() {
        // remove existing session
        if let existingSession = captureSession.inputs.first {
            captureSession.removeInput(existingSession)
        }

        // setup again
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            captureSession.commitConfiguration()
        } catch {
            os_log(.error, "Failed to create AVCaptureDeviceInput for camera")
        }
    }

    private func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                      mediaType: .video,
                                                                      position: .unspecified)
        for device in deviceDiscoverySession.devices {
            switch device.position {
            case .back:
                backCamera = device
            default:
                break
            }
        }
        selectCorrectCamera()
    }

    private func selectCorrectCamera() {
        // On iOS we default to the back camera, on Mac it's the front one
        currentCamera = backCamera
    }

    private func setupDeviceInputAndOutput() throws {
        guard let currentCamera = currentCamera else {
            os_log(.error, "currentCamera was nil while setting up the camera")
            return
        }

        if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            throw CameraCaptureSessionError.notAuthorized
        }

        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera)
            captureSession.addInput(captureDeviceInput)
            let photoOutput = AVCapturePhotoOutput()
            self.photoOutput = photoOutput
            photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])],
                                                       completionHandler: nil)
            captureSession.addOutput(photoOutput)

        } catch {
            os_log(.error, "Error setting up camera: \(error)")
        }

        // setup live classification
        setupLiveVideoOutput(captureSession: captureSession, videoOutput: videoOutput, videoOutputQueue: videoOutputQueue)
    }
}
