// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

extension String {
    /// The full event name for a `CoreAnalytics` training event.
    static var trainingEventName: Self {
        "\(eventPrefix).train"
    }

    /// The event prefix shared across all CoML `CoreAnalytics` events.
    private static var eventPrefix: Self {
        "com.apple.co-ml.app"
    }
}
