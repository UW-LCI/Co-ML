// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

final class ThumbnailListGeneratorTests: XCTestCase {
    func testGenerateWithLessThanMaxCountShouldReturnAllItemsInCorrectOrder() {
        let labelOneItems = [1]
        let labelTwoItems = [4, 5]
        let labelThreeItem: [Int] = []

        let generator = ThumbnailListGenerator(
            buckets: [labelOneItems, labelTwoItems, labelThreeItem],
            maxCount: 8
        )

        let list = generator.thumbnailList()
        XCTAssertEqual(
            list.count,
            3,
            "There should be 3 images in the list."
        )
        XCTAssertEqual([1, 5, 4], list, "Order should be 1, 5, 4")
    }

    func testListWithMoreThanMaxCountShouldReturnMaxCount() {
        let labelOneItems = [1]
        let labelTwoItems = Array(2...10)
        let labelThreeItem: [Int] = []

        let generator = ThumbnailListGenerator(
            buckets: [labelOneItems, labelTwoItems, labelThreeItem],
            maxCount: 3
        )
        let list = generator.thumbnailList()
        XCTAssertEqual(list.count, 3)
    }

    func testEmptyListShouldReturnNoThumbnails() {
        let generator = ThumbnailListGenerator<Int>(
            buckets: [],
            maxCount: 10
        )
        let list = generator.thumbnailList()
        XCTAssertTrue(list.isEmpty)
    }
}
