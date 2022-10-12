// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Combine

enum TrainingState {
    case notStarted
    case preparingDataset
    case datasetPrepared
    case finishedTraining
    case failed
}

protocol TrainingService: Sendable {
    func train(_ projectModelInfo: ProjectModelInfo) async throws -> AsyncStream<TrainingState>
}

/// Protocol extension facilitating project model info training verification.
extension TrainingService {

    /// Whether this project model info contains enough data for training.
    func hasEnoughDataToTrain(_ projectModelInfo: ProjectModelInfo) -> Bool {
        let minLabelsForTraining = 2
        return trainableLabelCount(projectModelInfo) >= minLabelsForTraining
    }

    func trainableLabelCount(_ projectModelInfo: ProjectModelInfo) -> Int {
        let minImagesPerLabelForTraining = 3
        return projectModelInfo.sampleIDsByLabelUUID.values.filter {
            $0.count >= minImagesPerLabelForTraining
        }.count
    }
}
