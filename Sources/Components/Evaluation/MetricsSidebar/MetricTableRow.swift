// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct MetricTableRow: Identifiable {
    let id = UUID()
    let label: String
    let percentCorrect: String
    let count: Int
}

#if DEBUG

extension [MetricTableRow] {
    static let fakeVegetables: Self = [
        .init(label: "Broccoli", percentCorrect: "83%", count: 16),
        .init(label: "Cheese", percentCorrect: "72%", count: 13),
        .init(label: "Mac and Cheese", percentCorrect: "72%", count: 13),
        .init(label: "Baby Broccoli", percentCorrect: "100%", count: 0),
        .init(label: "A Really Long Name", percentCorrect: "100%", count: 580)
    ]
}

#endif
