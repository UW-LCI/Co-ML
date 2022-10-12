// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Storage api for a collection of projects.
protocol ProjectCollectionStorage {
    /// Publishes projects on updates.
    var projectsPublisher: Published<[any ProjectStorage]>.Publisher { get }

    /// Load all project from store.
    func loadProjects() async throws

    /// Add a project to the store.
    ///
    /// - Parameter project: Project to be added.
    func add(project: Project) async throws

    /// Delete a project from the store.
    ///
    /// - Parameter id: Project `id`.
    func deleteProject(id: UUID) async throws
}
