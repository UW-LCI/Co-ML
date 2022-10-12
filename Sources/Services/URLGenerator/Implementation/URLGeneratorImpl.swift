// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

final class URLGeneratorImpl: URLGenerator {
    private let projectID: ProjectID
    private let projectDataPathComponent = "training-data"
    private let appDocumentDirectoryURL: URL

    init(projectID: ProjectID, appDocumentDirectoryURL: URL = URL.documentsDirectory) {
        self.projectID = projectID
        self.appDocumentDirectoryURL = appDocumentDirectoryURL
    }

    // MARK: - URLGenerator

    var projectDataDirectoryURL: URL {
        let projectDataURL = projectDirectoryURL
            .appendingPathComponent(projectDataPathComponent)
        return projectDataURL
    }

    var modelFileURL: URL {
        // Just call the model file "model.mlmodel"
        projectDirectoryURL
            .appending(component: "model")
            .appendingPathExtension("mlmodel")
    }

    var projectModelInfoURL: URL {
        projectDirectoryURL
            .appending(component: "modelMetadata")
            .appendingPathExtension("json")
    }

    var projectDirectoryURL: URL {
        URL.documentsDirectory.appendingPathComponent(projectID.uuidString)
    }
}
