// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

#if DEBUG

actor ProjectModelInfoRepositoryFake: ProjectModelInfoRepository {
    let projectID: ProjectID
    private var projectModelInfo: ProjectModelInfo?

    init(projectID: ProjectID, projectModelInfo: ProjectModelInfo? = nil) {
        self.projectID = projectID
        self.projectModelInfo = projectModelInfo
    }

    func updateProjectModelInfo(_ projectModelInfo: ProjectModelInfo?) async {
        self.projectModelInfo = projectModelInfo
    }

    // MARK: - ProjectModelInfoRepository

    func fetchProjectModelInfo() async throws -> ProjectModelInfo {
        guard let projectModelInfo else {
            throw DatabaseStorageServiceError.projectNotFound(projectID)
        }
        return projectModelInfo
    }
}

extension ProjectModelInfoRepository where Self == ProjectModelInfoRepositoryFake {
    static var fake: Self {
        .init(projectID: .fakeProjectID, projectModelInfo: .fake)
    }
}

#endif
