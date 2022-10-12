// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum CameraViewMode: CaseIterable {
    case collectionMode
    case classificationMode
}

extension CameraViewMode: CustomStringConvertible {
  var description: String {
    switch self {
    case .collectionMode:
      return "Collect Data"
    case .classificationMode:
      return "Preview Model"
    }
  }
}

struct CameraSettings: Equatable, Hashable {
    /// annotation can be nil *initially* when the caller didn't express a preference,
    /// and it can be nil because there *are no labels*.  When its nil, some things won't work
    /// If it's nil and there's a good other candidate, we automatically switch to the candidate
    /// in the loadLabels function
    var annotation: LabelAnnotation?
    var saveDestination: DataType
    var viewMode: CameraViewMode
}

extension CameraSettings {
    static let `default` = CameraSettings(annotation: nil, saveDestination: .training, viewMode: .collectionMode)
}

extension CameraSettings: CustomDebugStringConvertible {
    var debugDescription: String {
        "CameraSettings(\(annotation?.labelString ?? "<nil>"), \(saveDestination), \(viewMode))"
    }
}
