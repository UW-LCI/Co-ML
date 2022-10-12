// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A service that provides location, availability, and metadata about a user's model
protocol ModelStorageService {

    /// The project for which this service provides metadata.
    var projectID: ProjectID { get }

    /// The type of the model.
    var modelType: ModelType { get }

    /// URL where the model would be if it exists.
    var modelURL: URL { get }

    /// Metadata about the model file. `nil` if `!anyModelExists`.
    func fetchModelInfo() async -> ModelInfo?
}
