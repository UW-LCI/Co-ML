// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

/// Image repository responsible for fetching, and perhaps caching images.
protocol ImageFetchRepository: Sendable {

    /// Fetches an image for the given sample UUID.
    func fetchImage(sampleUUID: UUID) async throws -> UIImage
}
