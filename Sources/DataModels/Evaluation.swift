// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Defines an entity that represents the evaluation
struct Evaluation: Sendable, Identifiable, Codable {
    let id: UUID
    let title: String

    init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}
