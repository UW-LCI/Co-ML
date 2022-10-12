// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UniformTypeIdentifiers

/// Annotated sample data organized by training groups.
struct SingleLabelTrainingDataset: Codable, Sendable {
    var mediaType: UTType

    var sampleGroups: [SingleLabelTrainingGroup]
}

/// Build up from annotated sample data, that makes it convenient to write data to disk.
struct SingleLabelTrainingGroup: Codable, Sendable {
    var annotation: String
    var sampleIDs: [UUID]
}
