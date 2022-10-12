// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Encode pages that the RibbonGrid can open
enum GridViewLink {
    case openLabel(LabelAnnotation)
    case openCamera(for: LabelAnnotation)
}
