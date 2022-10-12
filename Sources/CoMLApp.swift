// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

@main
struct CoMLApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {

    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
