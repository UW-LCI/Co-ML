// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Populates the project dashboard.
struct ProjectDataset: Codable {
    var project: Project
    var samples: [AnnotatedSample]
}
