// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum DatabaseStorageServiceError: Error {
    case projectNotFound(ProjectID)
    case labelNotFound(LabelID)
    case invalidSamples(LabelID)
    case sampleNotFound(UUID)
    case sampleHasNoLabel(UUID)
    case notAvailable
    case labelUnavailable(id: String)
    case cantBatchAddToMultipleLabels(LabelID, LabelID)
}
