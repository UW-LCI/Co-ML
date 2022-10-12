// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import UniformTypeIdentifiers
import os.log

actor ImageStorageServiceImpl: ImageStorageService {

    private let sampleStorageService: SampleStorageService

    init(sampleStorageService: SampleStorageService) {
        self.sampleStorageService = sampleStorageService
    }

    // MARK: - ImageStorageService

    func fetchLabels(fromProjectWithID projectID: ProjectID) async throws -> [LabelAnnotation] {
        try await sampleStorageService.fetchLabels(projectID: projectID)
    }

    func fetchImages(withLabelID labelID: LabelID, dataType: DataType) async throws -> [LabeledImage] {
        var result: [LabeledImage] = []

        os_log(.info, "Fetching images for ImageStorageServiceImpl for label \(labelID), datatype \(String(describing: dataType))")

        let labelSamples = try await sampleStorageService.fetchSamples(labelID: labelID, dataType: dataType)
        for labelSample in labelSamples {
            let sampleData = labelSample.sampleData

            guard let image = UIImage(data: sampleData) else {
                assertionFailure("Couldn't create UIImage from sample data of \(sampleData.count) bytes")
                continue
            }

            let labeledImageID = LabeledImageID(existingSampleID: labelSample.id, labelID: labelID)
            let labeledImage = LabeledImage(existingLabeledImageID: labeledImageID,
                                            image: image,
                                            creationDate: labelSample.creationDate)

            result.append(labeledImage)
        }

        return result
    }

    func add(label: LabelAnnotation) async throws {
        try await sampleStorageService.add(label: label)
    }

    func add(labeledImage: LabeledImage) async throws {
        try await sampleStorageService.add(labeledImage: labeledImage)
    }

    func add(labeledImages: [LabeledImage]) async throws {
        try await sampleStorageService.add(labeledImages: labeledImages)
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        try await sampleStorageService.update(labelWithID: labelID, newLabelString: newLabelString)
    }
}
