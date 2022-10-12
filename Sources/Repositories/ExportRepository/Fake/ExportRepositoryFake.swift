// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

#if DEBUG

struct ExportRepositoryFake: ExportRepository {

    var projectInfo: ProjectInfo

    init(projectInfo: ProjectInfo = .fake) {
        self.projectInfo = projectInfo
    }

    // MARK: - ExportRepository

    func fetchProjectInfo() async -> ProjectInfo? {
        projectInfo
    }

    func prepareExportData() async throws -> URL {
        URL.temporaryDirectory
    }

    func cleanupExportData() async {
        // No-op
    }

    func prepareExportModel(modelName: String) async throws -> URL {
        fatalError("Update this fake!")
    }
}

extension ExportRepository where Self == ExportRepositoryFake {
    static var fake: Self {
        ExportRepositoryFake()
    }
}

#endif
