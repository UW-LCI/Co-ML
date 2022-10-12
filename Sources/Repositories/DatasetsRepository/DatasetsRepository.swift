// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Repository providing datasets to dependent components.
protocol DatasetsRepository: Sendable {

    var projectID: ProjectID { get }

    /// Asynchronously prepares the data set with the given dataset ID.
    func prepareDataset() async throws -> SingleLabelTrainingDataset
}

