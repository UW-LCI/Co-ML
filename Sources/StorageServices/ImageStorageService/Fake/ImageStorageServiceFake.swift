// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

actor ImageStorageServiceFake: ImageStorageService {
    func fetchSamples(labelID: UUID, limit: Int, datatype: DataType) async throws -> [Sample] {
        []
    }

    private var labelsByProjectID: [ProjectID: [LabelAnnotation]] = [:]
    private var imagesByLabelID: [LabelID: [LabeledImage]] = [:]

    init(labelsByProjectID: [ProjectID: [LabelAnnotation]] = [:], imagesByLabelID: [LabelID: [LabeledImage]] = [:]) {
        print("Initialising", #function, labelsByProjectID.keys, imagesByLabelID.keys)
        self.labelsByProjectID = labelsByProjectID
        self.imagesByLabelID = imagesByLabelID
    }

    func fetchLabels(fromProjectWithID projectID: ProjectID) async throws -> [LabelAnnotation] {
        labelsByProjectID[projectID, default: []]
    }

    func fetchImages(withLabelID labelID: LabelID, dataType: DataType) async throws -> [LabeledImage] {
        imagesByLabelID[labelID, default: []]
    }

    func add(label: LabelAnnotation) async throws {
        labelsByProjectID[label.id.projectID, default: []].append(label)
    }

    func add(labeledImage: LabeledImage) async throws {
        imagesByLabelID[labeledImage.labelID, default: []].append(labeledImage)
    }

    func add(labeledImages: [LabeledImage]) async throws {
        for labeledImage in labeledImages {
            try await add(labeledImage: labeledImage)
        }
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        fatalError("This fake doesn't support label updates.")
    }
}
