// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// API to access and update a project.
protocol ProjectStorage {
    var project: Project { get }

    /// Publishes project updates.
    var projectPublisher: Published<Project>.Publisher { get }

    /// Change project name.
    ///
    /// - Parameter newName: New name of project
    func changeName(to newName: String) async throws
}
