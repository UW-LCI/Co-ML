// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct FixedGrid<Item, Content: View>: View {
    private let builder: FixedGridBuilder<Item>
    private var content: (Item) -> Content

    init(builder: FixedGridBuilder<Item>, @ViewBuilder content: @escaping (Item) -> Content) {
        self.builder = builder
        self.content = content
    }

    var body: some View {
        Grid(alignment: .center, horizontalSpacing: 2, verticalSpacing: 2) {
            ForEach(builder.grid.indices, id: \.self) { row in
                GridRow {
                    ForEach(builder.grid[row].indices, id: \.self) { column in
                        content(builder.grid[row][column])
                    }
                }
            }
        }
    }
}
