// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A repository that streams evaluation states.
protocol EvaluationRepository: Sendable {

    var projectID: ProjectID { get }

    /// Evaluates using all the project's test samples.
    func evaluate() async -> EvaluationRepositoryState
}
