// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

final actor DatasetsRepositoryImpl: DatasetsRepository {
    let projectID: ProjectID
    private let projectModelInfoRepository: ProjectModelInfoRepository

    init(projectModelInfoRepository: ProjectModelInfoRepository) {
        self.projectModelInfoRepository = projectModelInfoRepository
        self.projectID = projectModelInfoRepository.projectID
    }

    // MARK: - DatasetsRepository

    func prepareDataset() async throws -> SingleLabelTrainingDataset {
        let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()

        var groups: [SingleLabelTrainingGroup] = []
        for label in projectModelInfo.labels {
            guard let sampleIDs = projectModelInfo.sampleIDsByLabelUUID[label.id.id] else {
                os_log(.info, "No training samples for label \(label)")
                continue
            }
            let group = SingleLabelTrainingGroup(annotation: label.labelString, sampleIDs: sampleIDs)
            groups.append(group)
        }

        let result = SingleLabelTrainingDataset(mediaType: .jpeg, sampleGroups: groups)
        return result
    }
}
