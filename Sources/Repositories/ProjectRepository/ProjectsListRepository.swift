// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

protocol ProjectsListRepository {
    /// Load project list view models.
    /// - Returns: View models.
    func load() async throws -> [ProjectTileViewState]

    /// Create a new project.
    /// - Parameter project: Project to be created.
    func create(project: Project) async throws

    /// Deletes projects with the specified identifiers.
    /// - Parameters:
    ///   - projectIDs: The identifiers of projects to be be deleted.
    ///   - isOnline: Whether the user is online. Shared projects cannot be purged while offline.
    func delete(projectIDs: Set<ProjectID>, isOnline: Bool) async throws
}

