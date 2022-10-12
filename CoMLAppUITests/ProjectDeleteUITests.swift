// Copyright 2026 Apple Inc. All rights reserved.

import XCTest

final class ProjectDeleteUITests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testDeleteMultipleProjectsDoesNotCrash() throws {
        let app = XCUIApplication()
        app.launchWithFakeCoreDataStackAndVirtualKeyboard()

        XCTContext.runActivity(named: "Create 3 new projects") { activity in

            app.buttons["Create Project"].tap()
            app.navigationBars.buttons["Add New Project"].tap() // Note, this is the toolbar button
            app.navigationBars.buttons["Add New Project"].tap()

        }

        XCTContext.runActivity(named: "select all projects") { activity in

            app.buttons["Edit"].tap()

            let projectButtons = app
                .scrollViews.buttons

            XCTAssertTrue(projectButtons.firstMatch.waitForExistence(timeout: 1.0))

            for projectButton in projectButtons.allElementsBoundByIndex {
                XCTAssertTrue(projectButton.label.hasPrefix("Project"), "some button is not a project")

                projectButton.tap()
            }
        }

        XCTContext.runActivity(named: "Delete Projects") { activity in
            app.buttons["Delete Projects"].tap()

            let deleteAlert = app.alerts.matching(identifier: "Delete 3 Projects").firstMatch

            _ = deleteAlert.waitForExistence(timeout: 5.0)
            deleteAlert.buttons["Delete"].tap()
        }

        XCTContext.runActivity(named: "Check projects deleted") { activity in

            /// Create ONE new project
            app.buttons["Create Project"].tap()

            let projectButtons = app
                .scrollViews.buttons

            XCTAssertTrue(projectButtons.firstMatch.waitForExistence(timeout: 1.0))

            var projectButtonCount = 0

            for projectButton in projectButtons.allElementsBoundByIndex {
                if projectButton.label.hasPrefix("Project") {
                    projectButtonCount += 1
                }
            }

            XCTAssertEqual(projectButtonCount, 1)
        }
    }
}
