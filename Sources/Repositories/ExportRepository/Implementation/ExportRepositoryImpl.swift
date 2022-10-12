// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

actor ExportRepositoryImpl: ExportRepository {
    let projectID: ProjectID
    let modelStorageService: ModelStorageService

    private let databaseStorageService: DatabaseStorageService

    init(projectID: ProjectID,
         modelStorageService: ModelStorageService,
         databaseStorageService: DatabaseStorageService) {
        self.projectID = projectID
        self.modelStorageService = modelStorageService
        self.databaseStorageService = databaseStorageService
    }

    // MARK: - ExportRepository

    func fetchProjectInfo() async -> ProjectInfo? {
        var projectMetadata: Project?
        do {
            projectMetadata = try await databaseStorageService.fetchProject(projectID: projectID)
        } catch let error {
            os_log(.error, #function, "Failed to update project metadata \(error)")
        }
        guard let projectMetadata else {
            return nil
        }

        let modelFilename = ProjectInfo.modelNameFromTitle(projectMetadata.title)
        let documentType = "Core ML Model"

        let modelInfo = await modelStorageService.fetchModelInfo()
        let labelNames: [String]
        if let modelInfoLabels = modelInfo?.projectModelInfo?.labels {
            labelNames = modelInfoLabels.map { $0.labelString }
        } else {
            os_log(.error, "No model info! Falling back to label names from project metadata.")
            labelNames = projectMetadata.labelNames
        }

        guard let modelInfo else {
            return nil
        }

        return ProjectInfo(prettyModelName: modelFilename,
                           projectType: modelStorageService.modelType,
                           dateTrained: modelInfo.creationDate,
                           documentType: documentType,
                           sizeInBytes: modelInfo.sizeInBytes,
                           labelNames: labelNames)
    }

    func anyModelExists() async -> Bool {
        let modelInfo = await modelStorageService.fetchModelInfo()
        return modelInfo != nil
    }

    /// Tries to create prettified file URL for export. If that fails, returns the not-pretty file URL
    func prepareExportModel(modelName: String) async throws -> URL {
        // this is getting run even when share sheet is not visible!!!!
        os_log(.info, "Generating new modelURL for export!")
        let tempURL = URL.temporaryDirectory.appendingPathComponent(modelName)
        try copyModelFile(to: tempURL)
        return tempURL
    }

    func prepareExportData() async throws -> URL {
        let bundle = DataExportBundle(projectID: projectID, databaseStorageService: databaseStorageService)
        return try await bundle.prepareExport()
    }

    func cleanupExportData() async {
        do {
            os_log(.info, "Will attempt data export folder cleanup.")
            try DataExportBundle.cleanupExportData(projectID: projectID)
            os_log(.info, "Cleanup successful: Data export folder deleted.")
        } catch let error {
            os_log(.error, "Failed to cleanup data export folder: \(error)")
        }
    }

    private func copyModelFile(to tempURL: URL) throws {
        // find current model
        let modelURL = modelStorageService.modelURL
        let fileManager = FileManager.default

        // remove any old exports
        if fileManager.fileExists(atPath: tempURL.path()) {
            try fileManager.removeItem(at: tempURL)
        }

        // then copy the latest model to the export path
        try fileManager.copyItem(at: modelURL, to: tempURL)
    }
}

