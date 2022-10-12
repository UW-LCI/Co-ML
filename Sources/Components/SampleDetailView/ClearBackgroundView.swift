// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

// When we move to iOS 16.5 we can use presentationBackground instead of this

/// From: https://stackoverflow.com/questions/64301041/swiftui-translucent-background-for-fullscreencover
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return InnerView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }

    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            superview?.superview?.backgroundColor = .clear
        }

    }
}
