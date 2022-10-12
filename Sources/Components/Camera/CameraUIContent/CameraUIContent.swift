// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

// a bare-bones camera UI with just the shutter button
typealias EmptyCameraView = CameraUIContent<EmptyView, EmptyView, EmptyView, EmptyView>

// a configurable camera UI
struct CameraUIContent<LeftMargin: View, CameraOverlay: View, AboveButtons: View, BelowButtons: View>: View {
    let leftMarginContents: LeftMargin
    let cameraOverlayContents: CameraOverlay
    let aboveShutterControls: AboveButtons
    let belowShutterControls: BelowButtons
    let showBackgroundMaterial: Bool

    init(leftMarginContents: LeftMargin, cameraOverlayContents: CameraOverlay, aboveShutterControls: AboveButtons, belowShutterControls: BelowButtons, showBackgroundMaterial: Bool = true) {
        self.leftMarginContents = leftMarginContents
        self.cameraOverlayContents = cameraOverlayContents
        self.aboveShutterControls = aboveShutterControls
        self.belowShutterControls = belowShutterControls
        self.showBackgroundMaterial = showBackgroundMaterial
    }

    var body: some View {
        HStack(alignment: .top) {
            leftCameraMargin
            Spacer()
            cameraOverlay
            Spacer()
            buttonBar
        }
    }

    private var leftCameraMargin: some View {
        VStack {
            leftMarginContents
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(minWidth: .tile.width)
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 10)
        .padding(.bottom)
        .background(.thickMaterial.opacity(showBackgroundMaterial ? 1.0 : 0.0))
    }

    private var cameraOverlay: some View {
        cameraOverlayContents
            .padding(.bottom, 75) // avoid mode toggle buttons
    }

    private var buttonBar: some View {
        CameraButtonBar(aboveShutterControls: aboveShutterControls,
                        belowShutterControls: belowShutterControls,
                        showBackgroundMaterial: showBackgroundMaterial)
    }

}

// creates a default empty CameraUIContent
extension CameraUIContent<EmptyView, EmptyView, EmptyView, EmptyView> {
    init() {
        leftMarginContents = EmptyView()
        cameraOverlayContents = EmptyView()
        aboveShutterControls = EmptyView()
        belowShutterControls = EmptyView()
        showBackgroundMaterial = true
    }
}
