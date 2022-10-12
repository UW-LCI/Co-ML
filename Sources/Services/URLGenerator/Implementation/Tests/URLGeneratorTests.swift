// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class URLGeneratorTests: XCTestCase {

    func testProjectDataDirectoryURLReturnsValidURL() throws {
        let generator = URLGeneratorImpl(
            projectID: projectID,
            appDocumentDirectoryURL: appDocumentDirectoryURL
        )
        let url = generator.projectDataDirectoryURL
        XCTAssertTrue(url.isDescendent(of: appDocumentDirectoryURL))
        XCTAssertTrue(url.pathComponents.contains(projectID.uuidString))
    }

    func testModelFileURLReturnsValidURL() throws {
        let generator = URLGeneratorImpl(
            projectID: projectID,
            appDocumentDirectoryURL: appDocumentDirectoryURL
        )
        let modelURL = generator.modelFileURL
        XCTAssertTrue(modelURL.isDescendent(of: appDocumentDirectoryURL))
        XCTAssertTrue(modelURL.pathComponents.contains(projectID.uuidString))
    }

    func testModelInfoURLIsValid() throws {
        let generator = URLGeneratorImpl(
            projectID: projectID,
            appDocumentDirectoryURL: appDocumentDirectoryURL
        )
        let modelInfoURL = generator.projectModelInfoURL
        XCTAssertTrue(modelInfoURL.isDescendent(of: appDocumentDirectoryURL))
        XCTAssertTrue(modelInfoURL.pathComponents.contains(projectID.uuidString))
    }

    // MARK: - Private

    private let appDocumentDirectoryURL = URL.documentsDirectory
    private let projectID = ProjectID()

    /*
     Note: This may change in the future, but currently we use the uuid string
     to store projects, since the project title can change, but the UUID is constant
     */
    private var projectFolderName: String {
        projectID.uuidString
    }
}

/// Extension for URL comparison testing.
extension URL {

    /// Checks whether the receiver is the descendent (a.k.a. child) of another URL.
    func isDescendent(of otherURL: URL) -> Bool {
        let path = path()
        let otherPath = otherURL.path()
        return path.hasPrefix(otherPath)
    }
}
