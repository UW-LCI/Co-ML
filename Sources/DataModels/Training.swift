// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Defines an entity that represents the training
struct Training: Sendable, Identifiable, Codable {
    let id: UUID
    let title: String
}
