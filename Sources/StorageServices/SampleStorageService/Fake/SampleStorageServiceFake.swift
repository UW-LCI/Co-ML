// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor SampleStorageServiceFake: SampleStorageService {

    private var labelsByProjectID: [ProjectID: [LabelAnnotation]] = [:]
    private var labelsByID: [LabelID: LabelAnnotation] = [:]
    private var samplesByLabelID: [LabelID: [AnnotatedSample]] = [:]

    // MARK: - SampleStorageService

    func fetchLabels(projectID: ProjectID) async throws -> [LabelAnnotation] {
        labelsByProjectID[projectID, default: []]
    }

    func fetchSamples(labelID: LabelID, dataType: DataType) async throws -> [AnnotatedSample] {
        try await Task.sleep(milliseconds: 50)
        return samplesByLabelID[labelID, default: []]
    }

    func add(label: LabelAnnotation) async throws {
        try await Task.sleep(milliseconds: 50)
        labelsByProjectID[label.id.projectID, default: []].append(label)
        labelsByID[label.id] = label
    }

    func add(labeledImage: LabeledImage) async throws {
        try await Task.sleep(milliseconds: 10)
        let labelID = labeledImage.labelID
        guard let label = labelsByID[labelID] else {
            throw SampleStorageServiceError.noSuchLabel(labelID)
        }
        guard let jpegData = labeledImage.image.jpegData(compressionQuality: 1.0) else {
            throw SampleStorageServiceError.failedToConvertImageToPNG
        }
        let sample = AnnotatedSample(id: UUID(),
                                     annotation: label,
                                     sampleType: .jpeg,
                                     sampleData: jpegData,
                                     creationDate: Date())
        samplesByLabelID[sample.annotation.id, default: []].append(sample)
    }

    func add(labeledImages: [LabeledImage]) async throws {
        for labeledImage in labeledImages {
            try await add(labeledImage: labeledImage)
        }
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        try await Task.sleep(milliseconds: 10)
        guard let _ = labelsByID[labelID] else {
            throw SampleStorageServiceError.noSuchLabel(labelID)
        }
        let updatedLabel = LabelAnnotation(labelID: labelID, label: newLabelString)
        labelsByID[labelID] = updatedLabel
        let indexOfExistingLabel = labelsByProjectID[labelID.projectID]?.firstIndex(where: { $0.id == labelID })
        labelsByProjectID[labelID.projectID]?[indexOfExistingLabel!] = updatedLabel
    }
}
