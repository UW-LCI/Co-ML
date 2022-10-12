// Copyright 2026 Apple Inc. All rights reserved.

/*
CoreDataStack

A class to set up the Core Data stack, observe Core Data notifications, and process persistent history.

 Adapted from https://developer.apple.com/documentation/coredata/synchronizing_a_local_store_to_the_cloud
*/

import CloudKit
import Combine
@preconcurrency import CoreData
import Foundation
import os.log

final class CoreDataStackImpl: CoreDataStack {
    enum CoreDataStrings {
        static let coreDataModel = "CoML"
        static let privateSqlitePath = "private.sqlite"
        static let sharedSqlitePath = "shared.sqlite"
        static let appTransactionAuthorName = "app"
        static let containerIdentifier = "com.apple.oss.coml"
        static let labelEntityName = SHLabel.entity().name
        static let sampleEntityName = SHSingleLabelSample.entity().name
        static let projectEntityName = SHSingleLabelClassifierProject.entity().name
        static let projectIDKey = "ProjectID"
    }

    static let shared = CoreDataStackImpl()

    let useCloudKit: Bool

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    lazy var imageFetchContext: NSManagedObjectContext = {
        persistentContainer.newBackgroundContext()
    }()

    private var _privatePersistentStore: NSPersistentStore?
    var privatePersistentStore: NSPersistentStore {
        return _privatePersistentStore!
    }

    private var _sharedPersistentStore: NSPersistentStore?
    var sharedPersistentStore: NSPersistentStore {
        return _sharedPersistentStore!
    }

    /**
     A persistent container that can load cloud-backed and non-cloud stores.
     */
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = initializeContainerFromBundle()

        addPrivateStore(to: container)
        addSharedStore(to: container)
        Self.configureContainerContext(context: container.viewContext)

        container.loadPersistentStores { loadedStoreDescription, error in
            self.onPersistentStoresLoaded(loadedStoreDescription: loadedStoreDescription, error: error, container: container)
        }

        NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange,
                                               object: container.persistentStoreCoordinator,
                                               queue: .main) { [weak self] info in

            guard let self else { return }

            // Notifications can include history tokens
            guard let historyToken = info.userInfo?["historyToken"] as? NSPersistentHistoryToken else {
                // skip those that do not
                return
            }

            self.processRemoteChange(token: historyToken)
        }

        return container
    }()

    /**
     An operation queue for handling history processing tasks: watching changes, deduplicating tags, and triggering UI updates if needed.
     */
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(useCloudKit: Bool = true) {
        self.useCloudKit = useCloudKit
    }

    func fakeNotify(projects _: Set<ProjectID>) {
        // Do nothing.  NSPersistentStoreRemoteChange tracking will handle the notification sending
    }

    func saveContext() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")  // This might need better error handling
        }
    }

    /**
     Function initializes the CoreData container. Throws a fatal error if it cannot initialize.
     Method is invoked when persistentContainer is first referenced, which occurs when ProjectRepository is initialized.
     */
    private func initializeContainerFromBundle() -> NSPersistentCloudKitContainer {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: CoreDataStrings.coreDataModel, withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing Managed Object Model from: \(modelURL)")
        }
        let container = NSPersistentCloudKitContainer(name: CoreDataStrings.coreDataModel, managedObjectModel: model)
        return container
    }

    private func addPrivateStore(to container: NSPersistentCloudKitContainer) {
        // Add Private Database
        let privateStoreDescription = container.persistentStoreDescriptions.first!
        let storesURL = privateStoreDescription.url!.deletingLastPathComponent()
        privateStoreDescription.url = storesURL.appendingPathComponent(CoreDataStrings.privateSqlitePath)
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if !useCloudKit {
            privateStoreDescription.cloudKitContainerOptions = nil
        }
    }

    private func addSharedStore(to container: NSPersistentCloudKitContainer) {
        //Add Shared Database
        let privateStoreDescription = container.persistentStoreDescriptions.first!
        let storesURL = privateStoreDescription.url!.deletingLastPathComponent()
        let sharedStoreURL = storesURL.appendingPathComponent(CoreDataStrings.sharedSqlitePath)
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = sharedStoreURL

        if useCloudKit {
            let containerIdentifier = privateStoreDescription.cloudKitContainerOptions!.containerIdentifier
            let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            sharedStoreOptions.databaseScope = .shared
            sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        }
        container.persistentStoreDescriptions.append(sharedStoreDescription)
    }

    private static func configureContainerContext(context: NSManagedObjectContext) {
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.transactionAuthor = CoreDataStrings.appTransactionAuthorName

        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        context.automaticallyMergesChangesFromParent = true
        do {
            try context.performAndWait {
                try context.setQueryGenerationFrom(.current)
            }
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)") // Needs better error handling
        }
    }

    private func onPersistentStoresLoaded(loadedStoreDescription: NSPersistentStoreDescription,
                                          error: Error?,
                                          container: NSPersistentCloudKitContainer) {
        if let loadError = error as NSError? {
            fatalError("###\(#function): Failed to load persistent stores:\(loadError)")
        }

        let coordinator = container.persistentStoreCoordinator
        let loadedStoreURL = loadedStoreDescription.url!

        if useCloudKit {
            switch loadedStoreDescription.cloudKitContainerOptions!.databaseScope {
            case .public:
                assertionFailure("Unexpected databaseScope public.")
            case .private:
                _privatePersistentStore = coordinator.persistentStore(for: loadedStoreURL)
            case .shared:
                _sharedPersistentStore = coordinator.persistentStore(for: loadedStoreURL)
            @unknown default:
                fatalError("Unknown database scope.")
            }
        } else {
            for store in coordinator.persistentStores {
                if store.url?.lastPathComponent == "private.sqlite" {
                    _privatePersistentStore = store
                } else if store.url?.lastPathComponent == "shared.sqlite" {
                    _sharedPersistentStore = store
                }
            }
        }
    }

    /// Fetch the Transaction History for a store, using a Token to get only the new
    /// - Parameters:
    ///   - context: the current managedObjectContext: probably a background
    ///   - store: the store to fetch transactions for : private or shared
    ///   - token: the corresponding history token.  Used to filter out old news.  Updated at the end of the call
    /// - Returns: The array of new transactions
    func getHistory(
        in context: NSManagedObjectContext,
        store: NSPersistentStore,
        updating token: inout NSPersistentHistoryToken?
    ) -> [NSPersistentHistoryTransaction] {

        // Fetch history received from outside the app since the last token
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!

        // Configure the request

        // This predicate was disabled because it allows changes made by *self* to show up.  This is necessary
        // since no-one is listening to Notification.Name.labeledImageUpdated right now, so all signals come through here.
        // historyFetchRequest.predicate = NSPredicate(format: "author != %@", CoreDataStrings.appTransactionAuthorName)

        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
        request.fetchRequest = historyFetchRequest
        // Restrict history search to one store (you must do this when using fetchHistory(after:))
        request.affectedStores = [store]

        let result: NSPersistentHistoryResult
        do {
            guard let historyResult = try context.execute(request) as? NSPersistentHistoryResult else {
                os_log(.error, "Failed to get result for history for store \(store.identifier)")
                return []
            }
            result = historyResult
        } catch {
            os_log(.error, "Failed to get history for store \(store.identifier)")
            return []
        }

        guard let transactions = result.result as? [NSPersistentHistoryTransaction] else {
            os_log(.error, "Unexpected type in array returned by history: \(type(of: result.result))")
            return []
        }

        // Update the history token using the last transaction.
        if let transaction = transactions.last {
            token = transaction.token
        }

        return transactions
    }

    private func processRemoteChange(token messageToken: NSPersistentHistoryToken) {

        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.performAndWait {

            // Track the last history token processed for a store, and write its value to file.
            // The historyQueue reads the token when executing operations,
            // and updates it after processing is complete.
            var sharedHistoryToken = PersistentToken(identifier: sharedPersistentStore.identifier)
            var privateHistoryToken = PersistentToken(identifier: privatePersistentStore.identifier)

            // If this is one of our head tokens, then we already have the new info; skip it
            guard privateHistoryToken.token != messageToken,
                  sharedHistoryToken.token != messageToken
            else {
                return
            }

            let privateTransactions = getHistory(
                in: taskContext,
                store: privatePersistentStore,
                updating: &privateHistoryToken.token
            )

            let sharedTransactions = getHistory(
                in: taskContext,
                store: sharedPersistentStore,
                updating: &sharedHistoryToken.token
            )

            if privateTransactions.isEmpty && sharedTransactions.isEmpty {
                os_log(.debug, "Processing a remote change - zero transactions")
                return
            }

            os_log(.info, "Processing a remote (+local) change with \(privateTransactions.count) private + \(sharedTransactions.count) shared Transactions")

            let allTransactions = privateTransactions + sharedTransactions
            let allChanges = allTransactions
                .compactMap(\.changes)
                .flatMap { $0 }

            var changedProjectIDs = Set<UUID>()

            for change in allChanges {
                if change.changeType == .delete {
                    // deletions to label and sample can be ignored because we also get an update on their relationship
                    if change.changedObjectID.entity.name == CoreDataStrings.projectEntityName,
                       let deletedProjectID = change.deletedProjectID {
                        changedProjectIDs.insert(deletedProjectID)
                    }
                } else {
                    if let projectID = getProjectIDForObject(taskContext: taskContext, change: change) {
                        changedProjectIDs.insert(projectID)
                    }
                }
            }
            NotificationCenter.default.post(projectIDs: changedProjectIDs)

        }
    }

    private func getProjectIDForObject(taskContext: NSManagedObjectContext, change: NSPersistentHistoryChange) -> UUID? {
        let entityName = change.changedObjectID.entity.name
        switch entityName {
        case CoreDataStrings.sampleEntityName:
            return unsafeProjectIdForSample(taskContext: taskContext, change: change)
        case CoreDataStrings.labelEntityName:
            return unsafeProjectIdForLabel(taskContext: taskContext, change: change)
        case CoreDataStrings.projectEntityName:
            return unsafeProjectIdForProject(taskContext: taskContext, change: change)
        default:
            return nil
        }
    }

    private func unsafeProjectIdForSample(taskContext: NSManagedObjectContext, change: NSPersistentHistoryChange) -> UUID? {
        do {
            guard let sample = try taskContext.existingObject(with: change.changedObjectID) as? SHSingleLabelSample else {
                os_log(.debug, "Task context has no sample with objectID \(change.changedObjectID)!")
                return nil
            }
            guard let label = sample.label else {
                os_log(.debug, "Sample with ID \(String(describing: sample.id)) has no label!")
                return nil
            }
            guard let project = label.project else {
                os_log(.debug, "Label with ID \(String(describing: label.id)) has no project!")
                return nil
            }
            guard let projectID = project.id else {
                os_log(.debug, "Project in label with ID \(String(describing: label.id)) has no ID!")
                return nil
            }
            return UUID(uuidString: projectID)

        } catch {
            os_log(.error, "Error getting sample with objectID \(change.changedObjectID) from task context: \(error)")
            return nil
        }
    }

    private func unsafeProjectIdForLabel(taskContext: NSManagedObjectContext, change: NSPersistentHistoryChange) -> UUID? {
        do {
            guard let label = try taskContext.existingObject(with: change.changedObjectID) as? SHLabel else {
                os_log(.debug, "Task context has no label with objectID \(change.changedObjectID)!")
                return nil
            }
            guard let project = label.project else {
                os_log(.debug, "Label with ID \(String(describing: label.id)) has no project!")
                return nil
            }
            guard let projectID = project.id else {
                os_log(.debug, "Project in label with ID \(String(describing: label.id)) has no ID!")
                return nil
            }
            return UUID(uuidString: projectID)

        } catch {
            os_log(.error, "Error getting label with objectID \(change.changedObjectID) from task context: \(error)")
            return nil
        }
    }

    private func unsafeProjectIdForProject(taskContext: NSManagedObjectContext, change: NSPersistentHistoryChange) -> UUID? {
        do {
            guard let project = try taskContext.existingObject(with: change.changedObjectID) as? SHSingleLabelClassifierProject else {
                os_log(.debug, "Task context has no project with objectID \(change.changedObjectID)!")
                return nil
            }
            guard let projectID = project.id else {
                os_log(.debug, "Project with objectID \(change.changedObjectID) has no ID!")
                return nil
            }
            return UUID(uuidString: projectID)

        } catch {
            os_log(.error, "Error getting project with objectID \(change.changedObjectID) from task context: \(error)")
            return nil
        }
    }
}

extension NSPersistentHistoryChange {
  // probably only for delete?
    var deletedProjectID: ProjectID? {
        if let projectIDString = self.tombstone?["id"] as? String,
           let projectID = UUID(uuidString: projectIDString) {
            return projectID
        }
        return nil
    }
}

extension NotificationCenter {

    /// Returns a sequence of CloudKit error codes corresponding to observed CloudKitContainer "export" events wrapping
    /// an error, indicating non-success.
    func cloudKitExportErrorCodes() -> AsyncCompactMapSequence<NotificationCenter.Notifications, Int> {
        notifications(named: NSPersistentCloudKitContainer.eventChangedNotification).compactMap { notification in
            guard let userInfo = notification.userInfo else {
                os_log(.debug, "No user info in notification \(notification)")
                return nil
            }
            guard let anyEvent = userInfo[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] else {
                os_log(.debug, "No event in user info \(userInfo)")
                return nil
            }
            guard let cloudEvent = anyEvent as? NSPersistentCloudKitContainer.Event else {
                os_log(.error, "Event \(String(describing: anyEvent)) not a cloud event")
                return nil
            }
            guard let ckerror = cloudEvent.error as? CKError else {
                os_log(.debug, "CloudEvent is \(cloudEvent).")
                return nil
            }
            if cloudEvent.type != .export {
                os_log(.debug, "Not posting any error for non-export events.")
                return nil
            }
            os_log(.error, "CloudKit error encountered in event: \(cloudEvent)")
            return ckerror.code.rawValue
        }
    }
}
