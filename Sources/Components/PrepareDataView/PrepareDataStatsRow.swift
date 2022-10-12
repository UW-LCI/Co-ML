// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct PrepareDataStatsRow: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

#if DEBUG

extension [PrepareDataStatsRow] {
    static let fakeVeggies: Self = [
        .fakeCarrot,
        .fakeBroccoli
    ]

    static let fakeFruits: Self = [
        .fakeApple,
        .fakeBanana,
        .fakeCarrot,
    ]
}

extension PrepareDataStatsRow {
    static let fakeCarrot: Self = .init(label: "Carrot", count: 2)
    static let fakeBroccoli: Self = .init(label: "Broccoli", count: 5)
    static let fakeApple: Self = .init(label: "Apple", count: 123)
    static let fakeBanana: Self = .init(label: "Banana", count: 45)
}

#endif
