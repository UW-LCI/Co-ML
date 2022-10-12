// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import CoreData

protocol CoreDataStack: Sendable {

    var context: NSManagedObjectContext { get }
    var imageFetchContext: NSManagedObjectContext { get }

    var privatePersistentStore: NSPersistentStore { get }
    var sharedPersistentStore: NSPersistentStore { get }
    var persistentContainer: NSPersistentCloudKitContainer { get }
    /// Just used by the CoreDataStackFake to send notifications because it doesn't have NSPersistentStoreRemoteChange
    func fakeNotify(projects: Set<ProjectID>)
    func saveContext()
}

extension CoreDataStack {
    func fakeNotify(project: ProjectID) {
        fakeNotify(projects: [project])
    }
}
