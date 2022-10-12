// Copyright 2026 Apple Inc. All rights reserved.

import XCTest

extension XCUIElementQuery {
    var elementWithKeyboardFocus: XCUIElement {
        self.element(matching: .hasKeyboardFocus)
    }
}

extension NSPredicate {
    static var hasKeyboardFocus: NSPredicate {
        NSPredicate(format: "hasKeyboardFocus == TRUE")
    }
}

extension XCUIApplication {
    /// Get the UI keyboard element
    ///
    /// Use this when you have triggered focus and expect the keyboard to be present
    /// Note: There might not be a keyboard because of simulator or hardware configuration
    /// If the keyboard is not on-screen It skips the remaining tests
    @discardableResult func expectKeyboard() throws -> XCUIElement {
        let keyboard = keyboards.element
        try XCTSkipIf(!keyboard.exists, "Keyboard does not exist")

        try XCTSkipIf(!keyboard.isHittable, "Skipping because virtual keyboard is not hittable.  Check that a virtual keyboard is available - use 'ignoreHardwareKeyboard' setting")
        return keyboard
    }

    // Hide keyboard if present.  If not present, skip rest of test
    func hideKeyboard() throws {
        let keyboard = try expectKeyboard()

        keyboard.buttons["Hide keyboard"].tap()
    }
}

final class LabelRenameUITests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    func testLabelRenameIsReflectedInProjectGallery() throws {
        let app = XCUIApplication()
        app.launchWithFakeCoreDataStackAndVirtualKeyboard()

        app.createAndOpenProject()

        XCTContext.runActivity(named: "Rename a label and go back") { activity in
            // Tap the "rename" button.
            app.scrollViews.otherElements.images["Label 1 menu label"].tap()
            app.collectionViews.buttons["Label 1 rename button"].tap()

            // Then, update the label name.
            app.typeText("00\n")

            // Navigate back.
            let navigationBar = app.navigationBars.firstMatch
            navigationBar.buttons["Back"].tap()
        }

        XCTContext.runActivity(named: "Check the new label name is in the gallery") { activity in
            let firstProjectButtonForCheckLabel = app.scrollViews.buttons.firstMatch
            let projectButtonLabel = firstProjectButtonForCheckLabel.label
            XCTAssertTrue(projectButtonLabel.contains("Label 100"))
        }
    }

    func testRenameAllLabelsWithoutPressingEnterAndGoingBack() throws {
        let app = XCUIApplication()
        app.launchWithFakeCoreDataStackAndVirtualKeyboard()

        XCTContext.runActivity(named: "Create a new project and open it") { activity in
            app.buttons["Create Project"].tap()
            let firstProjectButtonForOpenTap = app.scrollViews.buttons.firstMatch
            XCTAssertTrue(firstProjectButtonForOpenTap.waitForExistence(timeout: 2.0), "New Project Button Not Found")
            XCTAssertTrue(firstProjectButtonForOpenTap.label.hasPrefix("Project"), "New Project Button is not a Project Button")
            firstProjectButtonForOpenTap.tap()
        }

        XCTContext.runActivity(named: "Rename all labels and go back") { activity in
            let numbers = ["1", "2"]
            for number in numbers {
                // Tap the "rename" button for the current label.
                app.scrollViews.otherElements.images["Label \(number) menu label"].tap()
                app.collectionViews.buttons["Label \(number) rename button"].tap()

                app.typeText("00")
                if number == numbers.last {
                    // Hit enter on the second label.
                    app.typeText("\n")
                }
            }

            // Navigate back.
            let navigationBar = app.navigationBars.firstMatch
            navigationBar.buttons["Back"].tap()
        }

        XCTContext.runActivity(named: "Check the updated label names are reflected in the gallery") { activity in
            let firstProjectButtonForCheckLabel = app.scrollViews.buttons.firstMatch
            let projectButtonLabel = firstProjectButtonForCheckLabel.label
            XCTAssertTrue(projectButtonLabel.contains("Label 100"))
            XCTAssertTrue(projectButtonLabel.contains("Label 200"))
        }
    }
}
