// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

@MainActor
final class StringValidationTests: XCTestCase {

    func testEditToEmptyIsReverted() {
        XCTAssertEqual("".validated(previous: "Project"), "Project")
    }

    func testUpdateToWhitespaceRevertsToPrevious() {
        XCTAssertEqual("     ".validated(previous: "Label 1"), "Label 1")
    }

    func testEditWithDotIsReverted() {
        XCTAssertEqual("Label.".validated(previous: "Onions"), "Onions")
    }

    func testEditWithTildeIsReverted() {
        XCTAssertEqual("Label~".validated(previous: "Apples"), "Apples")
    }

    func testEditWithSlashIsReverted() {
        XCTAssertEqual("Label/".validated(previous: "Bananas"), "Bananas")
    }

    func testEditWithPathIsReverted() {
        XCTAssertEqual("~/../../tmp/".validated(previous: "Fruit Classifier"), "Fruit Classifier")
    }

    func testValidEditTrimsWhitespace() {
        XCTAssertEqual("New Label   ".validated(previous: "Old Label"), "New Label")
    }

    func testRevertMaintainsWhitespace() {
        XCTAssertEqual("~/../tmp/".validated(previous: "Old Label   "), "Old Label   ")
    }
}
