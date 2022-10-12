// Copyright 2026 Apple Inc. All rights reserved.


import Foundation
import XCTest

extension XCUIApplication {

    func launchWithFakeCoreDataStackAndVirtualKeyboard() {
        launchArguments = [
            "-coreDataStackFake", "true", // Don't write to user's PersistentStores!
            "-ignoreHardwareKeyboard", "true" // The virtual on-screen keyboard is preferred
        ]
        launch()
    }

    /// Create a project when in the gallery
    func createAndOpenProject() {
        XCTContext.runActivity(named: "Create a new project and open it") { activity in

            self.buttons["Create Project"].tap()

            let firstProjectButtonForOpenTap = self
                .scrollViews.buttons.firstMatch

            XCTAssertTrue(firstProjectButtonForOpenTap.waitForExistence(timeout: 5.0))
            XCTAssertTrue(firstProjectButtonForOpenTap.label.hasPrefix("Project"), "First button is not a project")

            firstProjectButtonForOpenTap.tap()
        }
    }
}
