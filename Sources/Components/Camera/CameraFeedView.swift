// Copyright 2026 Apple Inc. All rights reserved.

@preconcurrency import AVFoundation
import Foundation
import os.log
import SwiftUI

struct CameraFeedView: View {

    let imageStreamer: ScaledImageStreamer
    let classificationImageStreamer: ClassificationImageStreamer

    var body: some View {
        CameraRepresentable(imageStreamer: imageStreamer, classificationImageStreamer: classificationImageStreamer)
            .ignoresSafeArea() // needed for camera stream behind toolbar
    }
}

private struct CameraRepresentable: UIViewControllerRepresentable {

    let imageStreamer: ScaledImageStreamer
    let classificationImageStreamer: ClassificationImageStreamer

    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(imageStreamer: imageStreamer, classificationImageStreamer: classificationImageStreamer)
    }

    func updateUIViewController(_ cameraViewController: CameraViewController, context: Context) {
    }
}

@MainActor
final private class CameraViewController: UIViewController {

    private let cameraCaptureSession: CameraCaptureSession
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var tappedObserver: Any?
    private var orientationObserver: Any?

    init(imageStreamer: ScaledImageStreamer, classificationImageStreamer: ClassificationImageStreamer) {
        cameraCaptureSession = CameraCaptureSession(imageStreamer: imageStreamer, classificationImageStreamer: classificationImageStreamer)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = .large
        activityIndicator.frame = view.bounds
        activityIndicator.autoresizingMask = [ .flexibleHeight, .flexibleWidth ]
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        tappedObserver = listen(for: .cameraTappedNotification) { [weak self] in
            await self?.cameraCaptureSession.takePhoto()
        }
        orientationObserver = listen(for: UIDevice.orientationDidChangeNotification) { [weak self] in
            await self?.updateVideoOrientation()
        }
        Task { @MainActor in
            do {
                try await cameraCaptureSession.setupCamera()
                setupPreviewLayer()

            } catch CameraCaptureSessionError.notAuthorized {
                os_log(.info, "Caught not authorized error.")
                present(accessDeniedAlertController, animated: true)
            }

            activityIndicator.stopAnimating()
        }
    }

    deinit {
        print("Deinit Camera Session")
        NotificationCenter.default.removeObserver(tappedObserver!)
        NotificationCenter.default.removeObserver(orientationObserver!)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateVideoOrientation()
    }

    private func listen(for notificationName: Notification.Name,
                        completionHandler: @Sendable @escaping () async -> Void) -> Any {
        NotificationCenter.default.addObserver(forName: notificationName,
                                               object: nil,
                                               queue: nil) { _ in
            Task {
                await completionHandler()
            }
        }
    }

    private func setupPreviewLayer() {
        Task { @MainActor in
            let session = await cameraCaptureSession.captureSession()

            let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            cameraPreviewLayer.contentsGravity = .resizeAspectFill
            cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(cameraPreviewLayer)

            self.cameraPreviewLayer = cameraPreviewLayer
        }
    }

    private var accessDeniedAlertController: UIAlertController {
        let result = UIAlertController(
            title: String(localized: .cameraAccessDenied),
            message: String(localized: .toCaptureImagesGoToSettingsEtc),
            preferredStyle: .alert
        )

        result.addAction(.init(
            title: String(localized: .cancel),
            style: .cancel)
        )

        result.addAction(.init(
            title: String(localized: .settings),
            style: .default,
            handler: { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
        )

        return result
    }

    private func updateVideoOrientation() {
        guard let connection = cameraPreviewLayer?.connection else {
            os_log(.info, "Can't update video orientation: the preview connection isn't established.")
            return
        }
        let orientation = videoOrientationFromCurrentDeviceOrientation()
        connection.videoOrientation = orientation
        Task {
            await cameraCaptureSession.updateVideoOrientation(to: orientation)
        }
    }

    private func videoOrientationFromCurrentDeviceOrientation() -> AVCaptureVideoOrientation {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let windowOrientation = windowScene?.interfaceOrientation
        switch windowOrientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .landscapeLeft
        }
    }
}
