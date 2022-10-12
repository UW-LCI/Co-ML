// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import CoreData

final class CoreDataStackFake: CoreDataStack {
    private var _privatePersistentStore: NSPersistentStore?
    var privatePersistentStore: NSPersistentStore {
        return _privatePersistentStore!
    }

    private var _sharedPersistentStore: NSPersistentStore?
    var sharedPersistentStore: NSPersistentStore {
        return _sharedPersistentStore!
    }

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    lazy var imageFetchContext: NSManagedObjectContext = {
        persistentContainer.newBackgroundContext()
    }()

    /**
     A persistent container that can load cloud-backed and non-cloud stores.
     */
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "CoML", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let container = NSPersistentCloudKitContainer(name: "CoML", managedObjectModel: model)

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [persistentStoreDescription]

        container.loadPersistentStores { loadedStoreDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                self._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                self._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
            }
        }

        return container
    }()

    // the real coredatastack relies on NSPersistentStoreRemoteChange delivering update notifications on ALL changes (local and remote)
    // this fake one does not have that notification, so we need to send them manually
    func fakeNotify(projects: Set<ProjectID>) {
        NotificationCenter.default.post(projectIDs: projects)
    }

    func saveContext() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")  // Needs better error handling
        }
    }
}
