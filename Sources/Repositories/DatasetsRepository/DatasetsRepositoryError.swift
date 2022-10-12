// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Errors that may be thrown by this repository.
enum DatasetsRepositoryError: Error {

    case datasetNotFound(datasetID: UUID)

    case datasetFailedToLoad(datasetID: UUID)

    /// When a particular resource failed to load, a string is provided
    case datasetFailedToLoadResource(resourceName: String)
}
