// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Combine

#if DEBUG

actor TrainingServiceFake: TrainingService {

    func train(_ projectModelInfo: ProjectModelInfo) async throws -> AsyncStream<TrainingState> {
        .init { continuation in
            Task {
                continuation.yield(.preparingDataset)

                try await Task.sleep(seconds: 1)
                continuation.yield(.datasetPrepared)

                try await Task.sleep(seconds: 1)
                continuation.yield(.finishedTraining)
            }
        }
    }
}

extension TrainingService where Self == TrainingServiceFake {
    static var fake: Self {
        .init()
    }
}

#endif
