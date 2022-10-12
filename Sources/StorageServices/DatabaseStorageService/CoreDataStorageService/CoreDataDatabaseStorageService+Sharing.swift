// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import CoreData
import CloudKit
import os.log

extension CoreDataDatabaseStorageService {

    func fetchShare(projectID: ProjectID) throws -> CKShare? {
        try coreDataStack.context.performAndWait {
            guard let coreDataProject = try unsafeFetchCoreDataProject(projectID: projectID) else {
                throw DatabaseStorageServiceError.projectNotFound(projectID)
            }
            return try coreDataStack.persistentContainer.fetchShares(
                matching: [coreDataProject.objectID]
            )[coreDataProject.objectID]
        }
    }

    // Using SendableBox to suppress warnings about CKShare being unsendable
    func initiateNewShare(projectID: ProjectID) async throws -> SharingController.SendableShareMetadata {
        // Note: usually we do not let managed objects escape in this way
        guard let coreDataProject = try coreDataStack.context.performAndWait({
            try unsafeFetchCoreDataProject(projectID: projectID)
        }) else {
            throw DatabaseStorageServiceError.projectNotFound(projectID)
        }

        // ALERT: to permit this to be async it was necessary to let this coreDataProject escape it's perform block
        // this seems to be necessary but we avoid doing that elsewhere
        let (_, newShare, container) = try await coreDataStack.persistentContainer.share([coreDataProject], to: nil)

        await coreDataProject.managedObjectContext?.perform {
            newShare[CKShare.SystemFieldKey.title] = coreDataProject.title
        }
        return SendableBox(contents: (container, newShare))
    }

    func acceptShareInvitations(cloudKitShareMetadata: CKShare.Metadata) {
        guard self.persistentStoreForShare(share: cloudKitShareMetadata.share) == nil else {
            os_log(.info, "User accepted share for share already in store.")
            return
        }
        coreDataStack.persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: coreDataStack.sharedPersistentStore) { _, error in
            if let error {
                os_log(.error, "Error accepting share with error: \(error.localizedDescription)")
                return
            }
            NotificationCenter.default.post(name: .acceptedShare, object: nil)
        }
    }

    func getCKContainer() -> CKContainer {
        return CKContainer(identifier: CoreDataStackImpl.CoreDataStrings.containerIdentifier)
    }

    /// Fetch a project by ID
    /// - precondition: Unsafe: always call from inside a performAndWait
    func unsafeFetchCoreDataProject(projectID: ProjectID) throws -> SHSingleLabelClassifierProject? {
        let projectFetchRequest = SHSingleLabelClassifierProject.fetchRequest()
        let id = projectID.uuidString
        projectFetchRequest.predicate = NSPredicate(format: "id == %@", id)
        let projects = try coreDataStack.context.fetch(projectFetchRequest)
        return projects.first
    }

    private func persistentStoreForShare(share: CKShare) -> NSPersistentStore? {
        if let shares = try? coreDataStack.persistentContainer.fetchShares(in: coreDataStack.privatePersistentStore) {
            let zoneIDs = shares.map { $0.recordID.zoneID }
            if zoneIDs.contains(share.recordID.zoneID) {
                return coreDataStack.privatePersistentStore
            }
        }
        if let shares = try? coreDataStack.persistentContainer.fetchShares(in: coreDataStack.sharedPersistentStore) {
            let zoneIDs = shares.map { $0.recordID.zoneID }
            if zoneIDs.contains(share.recordID.zoneID) {
                return coreDataStack.sharedPersistentStore
            }
        }
        return nil
    }
}
