// Copyright 2026 Apple Inc. All rights reserved.

import UIKit
import os.log

protocol ThumbnailService {
    /// Fetch data associated with a label.
    ///
    /// - Parameters:
    ///   - metadata: Label metadata
    ///   - thumbnailLimit: Thumbnail fetch limit
    ///   - dataType: Data type
    /// - Returns: Label data
    func fetchLabelData(
        projectID: UUID,
        dataType: DataType,
        thumbnailLimit: Int
    ) async throws -> [LabelRibbon]
}

final actor ThumbnailServiceImpl: ThumbnailService {
    private let databaseStorageService: DatabaseStorageService

    /// Debugging label and and counts
    @MainActor static var debugCreatedCount = 0
    @MainActor let debugInstanceIndex = debugCreatedCount
    let debugCallerLabel: String

    init(databaseStorageService: DatabaseStorageService, debugCallerLabel: String = #fileID) {
        self.databaseStorageService = databaseStorageService

        // Update debug info
        self.debugCallerLabel = debugCallerLabel
        Task {@MainActor in
            Self.debugCreatedCount += 1
        }
    }

    /// Fetch data associated with a label.
    ///
    /// - Parameters:
    ///   - metadata: Label metadata
    ///   - thumbnailLimit: Thumbnail fetch limit
    ///   - dataType: Data type
    /// - Returns: Label data
    func fetchLabelData(
        projectID: UUID,
        dataType: DataType,
        thumbnailLimit: Int
    ) async throws -> [LabelRibbon] {

        let metadata = try await databaseStorageService.fetchLabelMetadata(
            projectID: projectID
        )
        let result = try await databaseStorageService.fetchLabelData(
            using: metadata,
            thumbnailLimit: thumbnailLimit,
            dataType: dataType
        )
        .map { convert(labelData: $0, dataType: dataType) }

        os_log(.info, "Fetched \(result.count) ribbons for \(self.debugCallerLabel)(\(self.debugInstanceIndex))")

        return result
    }

    private func convert(labelData: LabelData, dataType: DataType) -> LabelRibbon {
        let labeledImages: [LabeledImage] = labelData
            .images
            .lazy
            .compactMap { buildLabeledImage(sample: $0, labelID: labelData.labelID) }

        os_log(.info, "Fetched \(labeledImages.count) images for label '\(labelData.labelName)' for \(self.debugCallerLabel)(\(self.debugInstanceIndex))")

        return LabelRibbon(
            totalSampleCount: labelData.totalSampleCount,
            metadata: labelData.metadata,
            images: labeledImages
        )
    }

    /// Build up `LabeledImage` from a `Sample`.
    ///
    /// A labeled image created without passing in an `existingSampleID` will create a new UUID which will return nil from the database
    /// since no image exists with that ID.
    ///
    /// - Parameters:
    ///   - sample: Sample.
    ///   - labelID: Label ID
    /// - Returns: LabeledImage
    private func buildLabeledImage(sample: Sample, labelID: LabelID) -> LabeledImage? {
        guard
            let image = UIImage(data: sample.data),
            let existingSampleID = UUID(uuidString: sample.id)
        else { return nil }

        let labeledImageID = LabeledImageID(existingSampleID: existingSampleID, labelID: labelID)
        return LabeledImage(
            existingLabeledImageID: labeledImageID,
            image: image,
            creationDate: sample.creationDate
        )
    }
}
