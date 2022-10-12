// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A textual description of what kind of model this project contains
enum ModelType: String {
    case imageClassifier = "Image Classifier"

    var localized: String {
        switch self {
        case .imageClassifier:
            return String(localized: .imageClassifier)
        }
    }
}
