// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

extension String {

    /// Given an previous string, returns the receiver reduced to a valid string, or returns the previous string if the
    /// receiver is _invalid_ before or after trimming.
    func validated(previous: String) -> String {
        // If the new value is empty, revert.
        if isEmpty {
            return previous
        }
        // If it contains an invalid character, revert.
        for invalidCharacter in ["/", ".", "~"] where contains(invalidCharacter) {
            return previous
        }
        // Trim whitespace, if applicable.
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // Don't return empty string after trimming.
        if trimmed.isEmpty {
            return previous
        }
        return trimmed
    }
}
