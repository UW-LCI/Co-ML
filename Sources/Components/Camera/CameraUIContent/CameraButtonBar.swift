// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

/// A generic camera controls view with customizable above-shutter and below-shutter buttons
struct CameraButtonBar<UpperControls: View, LowerControls: View>: View {

    let aboveShutterControls: UpperControls
    let belowShutterControls: LowerControls

    let showBackgroundMaterial: Bool

    init(aboveShutterControls: UpperControls, belowShutterControls: LowerControls, showBackgroundMaterial: Bool = true) {
        self.aboveShutterControls = aboveShutterControls
        self.belowShutterControls = belowShutterControls
        self.showBackgroundMaterial = showBackgroundMaterial
    }

    var body: some View {
        VStack {
            VStack {
                // above shutter buttons
                Spacer()
                aboveShutterControls
            }
            shutterButton
            VStack {
                // below shutter buttons
                belowShutterControls
                Spacer()
            }
        }
        .frame(width: .tile.width) // keep fixed position on the screen
        .ignoresSafeArea() // needed to get shutter perfectly vertically center on the screen
        .background(.thickMaterial.opacity(showBackgroundMaterial ? 1.0 : 0.0))
    }

    private var shutterButton: some View {
        Button {
            os_log(.info, "Camera control button tapped")
            triggerCameraTappedNotification()
        } label: {
            Label(String(localized: .takePicture), systemImage: "circle.inset.filled")
                .labelStyle(.iconOnly)
                .font(.system(size: 55))
                .foregroundColor(.white)
                .padding()
        }
        .accessibilityInputLabels([
            String(localized: .takePicture),
            String(localized: .shutter),
            String(localized: .snap),
            String(localized: .cheese)
        ])
        .padding(.vertical, 15)
    }

    private func triggerCameraTappedNotification() {
        fireNotification(for: .cameraTappedNotification)
    }

    private func fireNotification(for notificationName: Notification.Name) {
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
}

// creates a default empty CameraButtonBar, that only has the shutter button
extension CameraButtonBar<EmptyView, EmptyView> {
    init() {
        aboveShutterControls = EmptyView()
        belowShutterControls = EmptyView()
        showBackgroundMaterial = true
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    CameraButtonBar()
}

#endif
