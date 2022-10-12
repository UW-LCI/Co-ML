// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

// Generic storage. Types used in this file should not be specific to any storage service.
// For example, `CoreData` should never be imported here.
protocol ItemStorage<Item, Store> {
    associatedtype Item: Codable & Sendable

    // Store provides apis for accessing the storage apis of individual items.
    associatedtype Store

    /// Publisher for updates to the items list.
    var itemsPublisher: Published<[Store]>.Publisher { get }

    /// Saves a single item.
    ///
    /// - Parameter item: Item to be saved.
    func add(item: Item) async throws

    /// Deletes a single item.
    ///
    /// - Parameter id: ID of item to be deleted.
    func delete(id: UUID) async throws

    /// Load all items.
    func load() async throws
}
