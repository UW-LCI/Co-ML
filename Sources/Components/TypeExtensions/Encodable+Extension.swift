// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

extension Encodable {
    /// Convert an `Encodable` object to a dictionary.
    ///
    /// - Returns: Dictionary representation of the `Encodable` object.
    func asDictionary() throws -> [String: Any] {
        let jsonObject = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(self),
            options: .allowFragments
        )

        guard let dictionary = jsonObject as? [String: Any] else {
            throw JSONParsingError.invalidDictionary
        }

        return dictionary
    }
}

enum JSONParsingError: Error {
    case invalidDictionary
}
