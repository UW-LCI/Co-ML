// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI

/// Encode actions that the RibbonGrid can request
enum GridViewAction {
    case showImage(id: LabeledImageID)
    case photosAppImport(to: LabelAnnotation)
    case filesAppImport(to: LabelAnnotation)
    case rename(LabelAnnotation, to: String)
    case delete(LabelAnnotation)
    case deleteImage(LabeledImageID)
}
