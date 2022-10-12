// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

extension Decodable {
    /// Initialize with a dictionary.
    ///
    /// - Parameter from: Dictionary.
    init(from: [String: Any]) throws {
        let data = try JSONSerialization.data(
            withJSONObject: from
        )
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}
