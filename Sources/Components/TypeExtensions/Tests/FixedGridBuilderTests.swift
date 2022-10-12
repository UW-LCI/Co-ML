// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class FixedGridBuilderTests: XCTestCase {
    let gridBuilder = FixedGridBuilder(
        items: Array(0..<20),
        rows: 2,
        columns: 4
    )

    func testGridCannotContainMoreThanRowxColumnsItems() {
        let totalItems = gridBuilder.grid.reduce([]) { $0 + $1 }
        XCTAssertEqual(
            totalItems.count,
            8,
            "Even though there are ten items, the grid can't be bigger than row times column"
        )
    }

    func testGridShouldHaveTwoRows() {
        XCTAssertEqual(gridBuilder.grid.count, 2)
    }

    func testGridShouldHaveFourColumns() {
        XCTAssertEqual(
            (gridBuilder.grid.first ?? []).count,
            4,
            "The number of items in each nested array should be the columns count."
        )
    }
}
