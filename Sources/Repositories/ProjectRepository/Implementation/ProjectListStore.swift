// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import UIKit

final actor ProjectListStore: ProjectsListRepository {
    private let thumbnailImageCount = 8
    private let databaseStorageService: DatabaseStorageService

    init(databaseStorageService: DatabaseStorageService) {
        self.databaseStorageService = databaseStorageService
    }

    func create(project: Project) async throws {
        try await databaseStorageService.create(project: project)
    }

    func load() async throws -> [ProjectTileViewState] {

        os_log(.debug, "Projects list store load…")
        var result: [ProjectTileViewState]!
        let dt = try ContinuousClock().measure {
            result = try databaseStorageService.fetchProjectTileViewStates()
        }
        os_log(.debug, "Projects list store load complete after \(dt).")
        return result
    }

    func delete(projectIDs: Set<ProjectID>, isOnline: Bool) async throws {
        try await databaseStorageService.delete(projectIDs: projectIDs, isOnline: isOnline)

        for projectID in projectIDs {
            cleanUpFiles(projectID)
        }
    }

    /// Cleans up all files corresponding to the given project ID.
    private func cleanUpFiles(_ projectID: ProjectID) {

        let urlGenerator = URLGeneratorImpl(projectID: projectID)

        do {
            try FileManager.default.removeItem(at: urlGenerator.projectDirectoryURL)
        } catch {
            os_log(.error, "An error occurred cleaning up \(projectID) files.")
        }
    }

    /// Fetch the samples associated with labels.
    ///
    /// - Parameter labels: Labels.
    /// - Returns: Thumbnail list (up to 8), and count of ALL samples.
    private func getThumbnailSamples(
        from labels: [LabelAnnotation]
    ) async throws -> (list: [AnnotatedSample], totalCount: Int) {
        var annotatedSamples: [[AnnotatedSample]] = []
        for label in  labels {
            try await annotatedSamples.append(
                databaseStorageService.fetchSamples(
                    labelID: label.id,
                    dataType: .training
                ).reversed() // Newest to oldest.
            )
        }

        let list = ThumbnailListGenerator(
            buckets: annotatedSamples,
            maxCount: thumbnailImageCount
        ).thumbnailList()

        return(list, annotatedSamples.flatMap { $0 }.count)
    }
}
