// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

actor ImageRepositoryImpl: ImageRepository {

    let projectID: ProjectID
    private let imageStorageService: ImageStorageService

    init(projectID: ProjectID, imageStorageService: ImageStorageService) {
        self.projectID = projectID
        self.imageStorageService = imageStorageService
    }

    // MARK: - ImageRepository

    func add(label: LabelAnnotation) async throws {
        try await imageStorageService.add(label: label)
    }

    func add(labeledImage: LabeledImage) async throws {
        try await imageStorageService.add(labeledImage: labeledImage)
    }

    func add(labeledImages: [LabeledImage]) async throws {
        try await imageStorageService.add(labeledImages: labeledImages)
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        try await imageStorageService.update(labelWithID: labelID, newLabelString: newLabelString)
    }
}
