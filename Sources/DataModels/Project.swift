// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Defines an entity that represents the project
struct Project: Sendable, Codable, Hashable {
    enum ShareState: Codable {
        case unknown

        /// The user owns this project but has not shared it.
        case notShared

        /// The user is the owner of this project.
        case shareOwner

        /// The user has received this project, and does not own it.
        case shareRecipient
    }
    var id: ProjectID
    var title: String
    var createdAt: Date
    var shareState = ShareState.unknown
    var labelNames: [String] = []
}

extension Project {
    /// Based on the project's share state, returns whether the project is shared or not.
    var isShared: Bool {
        switch shareState {
        case .unknown, .notShared:
            return false
        case .shareOwner, .shareRecipient:
            return true
        }
    }
}
