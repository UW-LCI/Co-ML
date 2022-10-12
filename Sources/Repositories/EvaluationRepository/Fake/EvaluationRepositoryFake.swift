// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import Foundation

#if DEBUG

@MainActor
final class EvaluationRepositoryFake: EvaluationRepository {
    let projectID: ProjectID
    private let stateToPublish: EvaluationRepositoryState
    private let publishInterval: Duration

    init(projectID: ProjectID,
         stateToPublish: EvaluationRepositoryState = .failed(DatabaseStorageServiceError.notAvailable),
         publishInterval: Duration = .milliseconds(100)) {
        self.projectID = projectID
        self.stateToPublish = stateToPublish
        self.publishInterval = publishInterval
    }

    // MARK: - EvaluationRepository

    func evaluate() async -> EvaluationRepositoryState {
        try! await Task.sleep(for: publishInterval)
        return stateToPublish
    }
}

@MainActor
extension EvaluationRepository where Self == EvaluationRepositoryFake {
    static var fake: Self {
        .init(projectID: .fakeProjectID)
    }
}

#endif
