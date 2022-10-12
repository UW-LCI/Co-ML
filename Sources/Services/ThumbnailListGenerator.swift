// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

private final class Stack<T> {
    private var items: [T] = []

    var isEmpty: Bool {
        items.isEmpty
    }

    init(items: [T]) {
        self.items = items
    }

    func pop() -> T? {
        items.isEmpty ? nil : items.removeLast()
    }
}

// Generic to support `UIImage`, `AnnotatedSample`, `LabeledImage` or any form that this image might take.
final class ThumbnailListGenerator<T> {
    private let stacks: [Stack<T>]
    private let maxCount: Int

    /// Build generator using buckets of images associated with each label.
    ///
    /// - Parameters:
    ///   - buckets: Images from each label.
    ///   - maxCount: Max amount of images for the thumbnail.
    init(buckets: [[T]], maxCount: Int) {
        self.stacks = buckets.map { Stack(items: $0) }
        self.maxCount = maxCount
    }

    /// Build a thumbnail list with `maxCount`. If we don't have enough, we return the entire list. The buckets
    /// should be sorted in the order you want them to be prior to being passed in.
    ///
    /// Pick the last item in each bucket until `maxCount` is reached. If we run out of images in a bucket, we just skip it.
    ///
    /// Project One
    /// Label One: [1]
    /// Label One Two: [2, 3, 4]
    /// Label One Three: []
    /// Label One Four: [5, 6, 7, 8, 9, 10]
    /// Max Count: 4
    /// Result ---> [1, 4, 10, 3]
    /// Only return the max count though there are more available.
    ///
    /// Project Two
    /// Label One: [1]
    /// Label Two: [2, 3, 4]
    /// Label Three: []
    /// Label Four: [5, 6, 7]
    ///
    /// Max Count: 8
    /// Result ---> [1, 4, 7, 3, 6, 2, 5]
    /// Return all seven items in a specified order
    ///
    /// - Returns: Thumbnail list.
    func thumbnailList() -> [T] {
        var items: [T] = []

        while items.count < maxCount {
            let newSet = stacks.compactMap { $0.pop() }
            if newSet.isEmpty {
                break
            }

            let remaining = maxCount - items.count
            items.append(contentsOf: newSet.prefix(remaining))
        }
        return items
    }
}
