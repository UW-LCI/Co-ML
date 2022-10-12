// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor ProjectModelInfoRepositoryImpl: ProjectModelInfoRepository {
    let projectID: ProjectID
    private let databaseStorageService: DatabaseStorageService

    init(projectID: ProjectID, databaseStorageService: DatabaseStorageService) {
        self.projectID = projectID
        self.databaseStorageService = databaseStorageService
    }

    // MARK: - ProjectModelInfoRepository

    func fetchProjectModelInfo() async throws -> ProjectModelInfo {
        try databaseStorageService.fetchProjectModelInfo(projectID: projectID)
    }
}
