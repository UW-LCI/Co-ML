// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum SampleDetailRepositoryError: Error {
    case failedToFetchSampleDetails(UUID)
    case failedToDecodeSample(UUID)
    case failedToUpdateLabelID(LabelID)
    case failedToDeleteSample
    case failedToMoveSampleToTesting
}
