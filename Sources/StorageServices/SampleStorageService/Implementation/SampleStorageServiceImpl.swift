// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor SampleStorageServiceImpl: SampleStorageService {

    let databaseStorageService: DatabaseStorageService

    init(databaseStorageService: DatabaseStorageService) {
        self.databaseStorageService = databaseStorageService
    }

    // MARK: - SampleStorageService

    func fetchLabels(projectID: ProjectID) async throws -> [LabelAnnotation] {
        try await databaseStorageService.fetchLabels(projectID: projectID)
    }

    func fetchSamples(labelID: LabelID, dataType: DataType) async throws -> [AnnotatedSample] {
        try await databaseStorageService.fetchSamples(labelID: labelID, dataType: dataType)
    }

    func add(label: LabelAnnotation) async throws {
        try await databaseStorageService.add(label: label)
    }

    func add(labeledImage: LabeledImage) async throws {
        try await databaseStorageService.add(labeledImage: labeledImage)
    }

    func add(labeledImages: [LabeledImage]) async throws {
        try await databaseStorageService.add(labeledImages: labeledImages)
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        try await databaseStorageService.update(labelWithID: labelID, newLabelString: newLabelString)
    }
}
