// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import UIKit

actor SampleDetailRepositoryImpl: SampleDetailRepository {
    let sampleID: UUID
    let dataType: DataType
    private let databaseStorageService: DatabaseStorageService

    /// Since this is subject to change, mark it as "volatile" so we don't make
    /// reasonable assumptions about its stability in re-entrant functions
    private var volatileLabelID: LabelID

    init(sampleID: UUID, dataType: DataType, databaseStorageService: DatabaseStorageService, initialLabelID: LabelID) {
        self.sampleID = sampleID
        self.dataType = dataType
        self.databaseStorageService = databaseStorageService
        self.volatileLabelID = initialLabelID
    }

    // MARK: - SampleDetailRepository

    func fetchSampleDetails() async throws -> SampleDetails {
        // In consideration of re-entrancy, capture label ID here.
        let labelID = volatileLabelID

        // Get all labels for the current project.
        let allProjectLabels = try await databaseStorageService.fetchLabels(projectID: projectID)

        // Get all _samples_ for the current label.
        let matchingSample = try  databaseStorageService.fetchSample(sampleID: sampleID)

        return try await sampleDetails(sample: matchingSample,
                                       labels: allProjectLabels,
                                       labelID: labelID)
    }

    func updateSelectedLabel(labelID: LabelID) async throws {
        let originalLabelID = volatileLabelID
        volatileLabelID = labelID
        do {
            try await databaseStorageService.moveSample(sampleID: sampleID,
                                                        toLabelWithID: labelID)

        } catch let error as DatabaseStorageServiceError {

            if case .labelNotFound(_) = error {
                os_log(.error, "The destination label wasn't found: \(error)")
                volatileLabelID = originalLabelID
            } else {
                os_log(.error, "An error occurred updating a sample's label: \(error)")
            }
        }
    }

    func deleteSample() async throws {
        try await databaseStorageService.deleteSample(sampleID: sampleID)
    }

    func moveToOppositeDataType() async throws {
        try databaseStorageService.moveSample(sampleID: sampleID, toDataType: dataType.oppositeDataType)
    }

    // MARK: - Private

    private var projectID: ProjectID {
        volatileLabelID.projectID
    }

    private func sampleDetails(sample: AnnotatedSample,
                               labels: [LabelAnnotation], labelID: LabelID) async throws -> SampleDetails {

        guard let image = UIImage(data: sample.sampleData) else {
            throw SampleDetailRepositoryError.failedToDecodeSample(sampleID)
        }

        let labeledImageID = LabeledImageID(existingSampleID: sampleID, labelID: labelID)
        let labeledImage = LabeledImage(existingLabeledImageID: labeledImageID,
                                        image: image,
                                        creationDate: sample.creationDate)

        return SampleDetails(image: labeledImage, labels: labels, selectedLabelID: labelID)
    }
}
