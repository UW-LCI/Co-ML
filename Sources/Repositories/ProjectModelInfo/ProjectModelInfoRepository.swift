// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A project-scoped repository that provides project model info instances on demand.
protocol ProjectModelInfoRepository: Sendable {

    var projectID: ProjectID { get }

    /// Fetch the latest model info for this project.
    func fetchProjectModelInfo() async throws -> ProjectModelInfo
}
