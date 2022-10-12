// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor LabelDetailRepositoryImpl: LabelDetailRepository {
    let labelID: LabelID
    let dataType: DataType

    private let projectModelInfoRepository: ProjectModelInfoRepository

    init(labelID: LabelID, dataType: DataType, projectModelInfoRepository: ProjectModelInfoRepository) {
        self.labelID = labelID
        self.dataType = dataType
        self.projectModelInfoRepository = projectModelInfoRepository
    }

    // MARK: - LabelDetailRepository

    /// Fetches image IDs corresponding to this label detail view model.
    func fetchImageIDs() async throws -> [LabeledImageID] {
        let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()

        let sampleIDsDictionary: [UUID: [UUID]]
        switch dataType {
        case .training:
            sampleIDsDictionary = projectModelInfo.sampleIDsByLabelUUID
        case .testing:
            sampleIDsDictionary = projectModelInfo.testSampleIDsByLabelUUID
        }

        guard let sampleIDs = sampleIDsDictionary[labelID.id] else {
            throw DatabaseStorageServiceError.labelNotFound(labelID)
        }

        let result = sampleIDs.map { LabeledImageID(existingSampleID: $0, labelID: labelID) }

        return result
    }
}
