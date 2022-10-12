// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

#if DEBUG

final class ProjectListStoreFake: ProjectsListRepository {
    enum ProjectListFakeError: Error {
        case itemNotFound
    }

    private(set) var gridItems: [ProjectTileViewState]

    init(gridItems: [ProjectTileViewState] = []) {
      self.gridItems = gridItems
    }

    func load() async throws -> [ProjectTileViewState] {
        gridItems
    }

    func delete(projectIDs: Set<ProjectID>, isOnline: Bool) async throws {
        for projectID in projectIDs {
            if let index = gridItems.firstIndex(where: { $0.id == projectID }) {
                gridItems.remove(at: index)
            } else {
                throw ProjectListFakeError.itemNotFound
            }
        }
    }

    func create(project: Project) async throws {
        gridItems.append(
            ProjectTileViewState(
                project: project,
                thumbnails: [],
                totalSampleCount: 0
            )
        )
    }
}

extension ProjectsListRepository where Self == ProjectListStoreFake {
    static var fake: Self {
        .init(gridItems: .fake)
    }
}

#endif
