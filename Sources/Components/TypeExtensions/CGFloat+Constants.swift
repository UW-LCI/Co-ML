// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

extension CGFloat {
    enum tile { // see Sketch design doc for reference
        static let cornerRadius = 6.0
        static let width = 110.0
        static let height = 110.0
        static let shadowRadius = 2.0
        static let spacing = 4.0
    }

    enum sidebar { // see Sketch design doc for reference
        static let padding = 20.0
        static let width = 300.0
        static let fontSize = 17.0
    }

    enum barchart {
        static let barMinHeight = 40.0 // minimum height for bars for legibility
        static let maxEvalChartHeight = 200.0
    }

    enum list {
        static let labelWidth = 100.0
        static let labelHeight = 30.0
    }

    enum modal {
        static let cornerRadius = 10.0
        static let toolbarPadding = 15.0
    }
}
