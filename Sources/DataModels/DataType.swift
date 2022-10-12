// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum DataType: String, Identifiable, CaseIterable {
    case training
    case testing

    func matches(purpose: String?) -> Bool {
        guard let purpose else {
            return self == .training // Nil matches training for backwards compatibility.
        }
        return purposeString == purpose
    }

    var purposeString: String {
        rawValue
    }

    var id: String {
        rawValue
    }

    /// For data export/import, how this DataType should appear in the filesystem
    var directoryName: String {
        self == .training ? "train" : "test"
    }

    var oppositeDataType: DataType {
        self == .training ? .testing : .training
    }

    var localizedDescription: String {
        switch self {
        case .training:
            return String(localized: .training)

        case .testing:
            return String(localized: .testing)
        }
    }
}
