// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum SampleStorageServiceError: Error {
    case noSuchLabel(LabelID)
    case failedToConvertImageToPNG
}
