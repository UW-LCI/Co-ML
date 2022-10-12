// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum ProjectPage: CustomStringConvertible {
    case trainingData
    case training
    case evaluation
    case export

    var localizedTitle: String {
        switch self {
        case .trainingData:
            return String(localized: .prepare)

        case .training:
            return String(localized: .train)

        case .evaluation:
            return String(localized: .test)

        case .export:
            return String(localized: .export)
        }
    }

    var dataType: DataType {
        switch self {
        case .evaluation:
            return .testing

        case .export, .training:
            assertionFailure("Can't query data type for project page \(self). Default to training.")
            fallthrough
        case .trainingData:
            return .training
        }
    }

    // MARK: - CustomStringConvertible

    var description: String {
        localizedTitle
    }
}
