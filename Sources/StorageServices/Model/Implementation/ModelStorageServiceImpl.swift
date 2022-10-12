// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

actor ModelStorageServiceImpl: ModelStorageService {

    let projectID: ProjectID
    let modelURL: URL
    let modelMetadataURL: URL
    let modelType: ModelType

    init(projectID: ProjectID, modelURL: URL, modelMetadataURL: URL, modelType: ModelType) {
        self.projectID = projectID
        self.modelURL = modelURL
        self.modelMetadataURL = modelMetadataURL
        self.modelType = modelType
    }

    func fetchModelInfo() async -> ModelInfo? {
        guard await anyModelExists(),
              let lastTrained = await lastTrained(),
              let modelSizeBytes = await modelSizeBytes()
        else {
            return nil
        }

        let projectModelInfo = ProjectModelInfo(loadedFrom: modelMetadataURL)

        return ModelInfo(modelType: modelType,
                         modelURL: modelURL,
                         sizeInBytes: modelSizeBytes,
                         creationDate: lastTrained,
                         projectModelInfo: projectModelInfo)
    }
}

// MARK: - Private

extension ModelStorageServiceImpl {

    private func anyModelExists() async -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: modelPath) && fileManager.isReadableFile(atPath: modelPath)
    }

    private func modelSizeBytes() async -> Int64? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: modelPath)
            return attr[.size] as? Int64
        } catch let error {
            os_log(.error, "Something went wrong checking model file size", error.localizedDescription)
        }
        return nil
    }

    private func lastTrained() async -> Date? {
        let anyModelExists = await anyModelExists()
        if anyModelExists {
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: modelPath)
                return attr[.modificationDate] as? Date
            } catch let error {
                os_log(.error, "Something went wrong checking model file modification date", error.localizedDescription)
            }
        }
        return nil
    }

    private var modelPath: String {
        modelURL.path()
    }
}
