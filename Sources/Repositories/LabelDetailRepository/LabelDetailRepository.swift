// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

protocol LabelDetailRepository: Sendable {

    /// The label ID for which this repository provides image IDs.
    var labelID: LabelID { get }

    /// The data type of the provided image IDs.
    var dataType: DataType { get }

    /// Fetches image IDs for this repository's label.
    func fetchImageIDs() async throws -> [LabeledImageID]
}
