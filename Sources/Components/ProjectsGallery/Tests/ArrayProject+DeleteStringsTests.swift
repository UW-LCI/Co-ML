// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class ArrayProjectDeleteStringsTests: XCTestCase {
    func testSingleProjectArrayProducesDeleteTitleWithProjectName() {
        let oneProject: [Project] = [
            .init(id: ProjectID(), title: "Only Project", createdAt: Date())
        ]
        XCTAssertEqual(oneProject.deleteConfirmationTitle, "Delete “Only Project”")
    }

    func testEmptyProjectArrayProducesDeleteTitleWithZeroCount() {
        let noProjects: [Project] = []
        XCTAssertEqual(noProjects.deleteConfirmationTitle, "Delete")
    }

    func testMultiProjectArrayProducesDeleteTitleWithZeroCount() {
        let multipleProjects: [Project] = [
            .init(id: ProjectID(), title: "These", createdAt: Date()),
            .init(id: ProjectID(), title: "titles", createdAt: Date()),
            .init(id: ProjectID(), title: "shouldn't", createdAt: Date()),
            .init(id: ProjectID(), title: "appear", createdAt: Date())
        ]
        XCTAssertEqual(multipleProjects.deleteConfirmationTitle, "Delete 4 Projects")
    }
}
