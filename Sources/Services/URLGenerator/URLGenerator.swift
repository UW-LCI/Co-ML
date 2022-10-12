// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

protocol URLGenerator: Sendable {

    /// Get URL to store annotated project data.
    ///
    /// - Returns: URL at which project data will be written.
    var projectDataDirectoryURL: URL { get }

    /// Generate URL that may be used to write a model file to disk.
    ///
    /// - Returns: URL to which a model file will be written.
    var modelFileURL: URL { get }

    /// URL that may be used to write model metadata to disk.
    var projectModelInfoURL: URL { get }

    /// The URL in which all the above URLs reside.
    var projectDirectoryURL: URL { get }
}
