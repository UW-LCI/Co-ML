// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

enum DataExportState {
    case prepareData
    case prepInProgress
    case readyToExport(dataURL: URL)
    case cleanInProgress
    case error
}
