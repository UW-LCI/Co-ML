// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

final class FixedGridBuilder<Item> {
    private let items: [Item]
    private let columns: Int
    let rows: Int

    /// Grid builder.
    lazy var grid: [[Item]] = {
        guard !items.isEmpty else { return [] }

        var grid: [[Item]] = []
        for row in 0..<rows {
            var itemRow: [Item] = []
            grid.append((0..<columns).map { items[oneDIndex(row: row, column: $0)] })
        }

        return grid
    }()

    init(items: [Item], rows: Int, columns: Int) {
        self.items = items
        self.rows = rows
        self.columns = columns
    }

    /// Get the one dimensional index that matches a 2D grid.
    ///
    /// - Parameters:
    ///   - row: Row of the item
    ///   - column: Column of the item.
    ///
    /// Item count: 9
    /// Rows: 3
    /// Columns: 4
    ///
    /// ****
    /// **^*
    /// ****
    ///
    /// Find the index of the ^, with zero based indices.
    /// Row = 1
    /// Column: 2
    /// (1*4 + 2) % 9 = 6

    /// - Returns: Item's index.
    private func oneDIndex(row: Int, column: Int) -> Int {
        (row * columns + column) % items.count
    }
}
