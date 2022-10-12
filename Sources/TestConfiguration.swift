// Copyright 2026 Apple Inc. All rights reserved.


import Foundation
import SwiftUI
@testable import CoMLApp

#if DEBUG

extension CoMLApp {
    func debugConfig() {
        TestConfiguration.ignoreHardwareKeyboard()
    }
}

enum TestConfiguration {
    /// Unit tests can choose to use virtual keyboard
    /// * Works on simulators and physical devices
    /// * Allow more realistic configuration and test for focus
    static func ignoreHardwareKeyboard() {
        // https://stackoverflow.com/questions/38010494/is-it-possible-to-toggle-software-keyboard-via-the-code-in-ui-test
        if UserDefaults.standard.bool(forKey: "ignoreHardwareKeyboard") {
            // Disable hardware keyboards.
            let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
            UITextInputMode.activeInputModes
            // Filter `UIKeyboardInputMode`s.
                .filter({ $0.responds(to: setHardwareLayout) })
                .forEach { $0.perform(setHardwareLayout, with: nil) }
        }
    }
}

#endif
