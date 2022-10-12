// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import CloudKit
import CoreData
import os.log

/**
 * Defines the APIs to perform CoreData operations
 */
final class CoreDataDatabaseStorageService: DatabaseStorageService {
    private let defaultLabelCount = 2

    static let shared: CoreDataDatabaseStorageService = {
        if UserDefaults.standard.bool(forKey: "coreDataStackFake") {
            os_log(.error, "Using in-memory CoreDataStackFake")
            return CoreDataDatabaseStorageService(coreDataStack: CoreDataStackFake())
        } else {
            return CoreDataDatabaseStorageService(coreDataStack: CoreDataStackImpl())
        }
    }()

    let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Project

    /// Rename a project.
    ///
    /// - Parameters:
    ///   - id: ID of project.
    ///   - newName: Project's new name.
    func renameProject(id: UUID, newName: String) async throws {
        try await coreDataStack.context.perform { [self] in
            let project = try unsafeFetchCoreDataProject(id: id)

            project.title = newName
            try coreDataStack.context.save()
        }

        coreDataStack.fakeNotify(project: id)
    }

    func create(project: Project) async throws {
        coreDataStack.context.performAndWait {
            let newProject = SHSingleLabelClassifierProject(context: coreDataStack.context)
            newProject.title = project.title
            newProject.id = project.id.uuidString
            newProject.creationDate = Date()

            newProject.labels = NSSet(
                array: (1...defaultLabelCount).map { unsafeCreateDefaultLabel(index: $0) }
            )
            coreDataStack.context.assign(newProject, to: coreDataStack.privatePersistentStore)
            coreDataStack.saveContext()
        }

        coreDataStack.fakeNotify(project: project.id)
    }

    /// Fetches a project's metadata, given project's id
    func fetchProject(projectID: ProjectID) async throws -> Project {
        try await coreDataStack.context.perform {
            let projectObject = try self.unsafeFetchCoreDataProject(id: projectID)

            let project = self.unsafeBuildProject(from: projectObject)
            os_log(.info, #function, "has fetched project metadata \(projectID.uuidString) : \(String(describing: project))")
            return project
        }
    }

    /// Fetch a project title, given project's id.
    ///
    /// - Parameter id: Project ID
    /// - Returns: Project's title
    func fetchProjectTitle(id: UUID) async throws -> String {
        try await coreDataStack.context.perform {
            let coreDataProject = try self.unsafeFetchCoreDataProject(id: id)

            let title = coreDataProject.title
            os_log(.info, #function, "has fetched project title for \(id.uuidString) \(title ?? "<nil>")")
            return title ?? ""
        }
    }

    func fetchProjects() async throws -> [Project] {
        try await coreDataStack.context.perform {
            let projectFetchRequest = SHSingleLabelClassifierProject.fetchRequest()
            var shProjects = try self.coreDataStack.context.fetch(projectFetchRequest)
            return shProjects.map { shProject in
                self.unsafeBuildProject(from: shProject)
            }
        }
    }

    func delete(projectID: ProjectID, isOnline: Bool) async throws {
        try await delete(projectIDs: [ projectID ], isOnline: isOnline)
    }

    /// Delete API that allows multiple projects to be deleted in 1 call. Should be used for multi-delete.
    func delete(projectIDs: Set<ProjectID>, isOnline: Bool) async throws {
        try coreDataStack.context.performAndWait {

            var deletedProjectIDs: [ProjectID] = []
            var numDeletedShares = 0

            for projectID in projectIDs {
                let fetchRequest = SHSingleLabelClassifierProject.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", projectID.uuidString)
                let projects = try coreDataStack.context.fetch(fetchRequest)
                guard let project = projects.first else {
                    os_log(.error, "No project could be fetched with ID \(projectID)")
                    continue
                }

                // Add the object ID to either the private or shared array.
                let objectID = project.objectID
                if let share = try coreDataStack.persistentContainer.fetchShares(matching: [objectID])[objectID] {
                    if isOnline {
                        os_log(.debug, "Purging project with ID \(projectID)…")
                        coreDataStack.persistentContainer.purgeObjectsAndRecordsInZone(
                            with: share.recordID.zoneID,
                            in: objectID.persistentStore) { purgedZoneID, error in
                                os_log(.debug, "Purged project \(projectID) from zone with ID \(purgedZoneID)? or error \(error).")
                            }
                        deletedProjectIDs.append(projectID)
                        numDeletedShares += 1
                    } else {
                        os_log(.info, "WARNING! Not purging project \(projectID) when offline.")
                    }
                } else {
                    // Delete here if we don't support batch deletes (i.e., in tests)
                    coreDataStack.context.delete(project)
                    deletedProjectIDs.append(projectID)
                }
            }

            // Save after all deletion is complete.
            coreDataStack.saveContext()

            os_log(.info, "Deleted projects with IDs \(deletedProjectIDs) (\(numDeletedShares) shares).")

            if deletedProjectIDs.isEmpty {
                throw DatabaseStorageServiceError.notAvailable
            }
        }
        coreDataStack.fakeNotify(projects: projectIDs)
    }

    func fetchProjectModelInfo(projectID: ProjectID) throws -> ProjectModelInfo {
        try coreDataStack.context.performAndWait {

            // 1. Fetch the project.
            let coreDataProject = try self.unsafeFetchCoreDataProject(id: projectID)

            // 2. For each of the project's labels, fetch and store the label's sorted sample UUIDs arrays.
            let coreDataLabels = coreDataProject.unsafeSortedLabels
            var sampleIDsByLabelUUID: [UUID: [UUID]] = [:]
            var testSampleIDsByLabelUUID: [UUID: [UUID]] = [:]
            for coreDataLabel in coreDataLabels {
                guard let labelUUIDString = coreDataLabel.id,
                      let labelUUID = UUID(uuidString: labelUUIDString) else {
                    assertionFailure("A core data label has no ID")
                    continue
                }
                sampleIDsByLabelUUID[labelUUID] = coreDataLabel.fetchUnsafeSampleUUIDs(dataType: .training)
                testSampleIDsByLabelUUID[labelUUID] = coreDataLabel.fetchUnsafeSampleUUIDs(dataType: .testing)
            }

            // 3. Extract label annotations from the project.
            let labels: [LabelAnnotation] = coreDataLabels.compactMap {
                LabelAnnotation(unsafeCoreDataLabel: $0, projectID: projectID)
            }

            return ProjectModelInfo(version: "1.1",
                                    labels: labels,
                                    sampleIDsByLabelUUID: sampleIDsByLabelUUID,
                                    testSampleIDsByLabelUUID: testSampleIDsByLabelUUID)
        }
    }

    func fetchProjectTileViewStates() throws -> [ProjectTileViewState] {
        try coreDataStack.context.performAndWait {
            let coreDataProjects = try self.unsafeFetchAllCoreDataProjects()

            var result: [ProjectTileViewState] = []
            for project in coreDataProjects {
                let tileViewState = try unsafeBuildTileViewState(coreDataProject: project)
                result.append(tileViewState)
            }

            return result
        }
    }

    // MARK: - Private

    /// Builds a tile view state from the given core data project.
    /// - precondition: Unsafe: always call from inside a performAndWait
    private func unsafeBuildTileViewState(coreDataProject: SHSingleLabelClassifierProject) throws -> ProjectTileViewState {
        let sampleIDArrays = try unsafeBuildSampleIDArrays(sortedLabels: coreDataProject.unsafeSortedLabels)
        let totalSampleCount = sampleIDArrays.reduce(0) { $0 + $1.count }
        let thumbnailSampleIDs = buildProjectTileThumbnailSampleIDs(sampleIDArrays: sampleIDArrays)
        let project = unsafeBuildProject(from: coreDataProject)

        return ProjectTileViewState(project: project,
                                         thumbnailSampleIDs: thumbnailSampleIDs,
                                         totalSampleCount: totalSampleCount)
    }

    /// Given an array of sorted core data labels, adds all sorted sample IDs in those labels, from both the `training`
    /// and `testing` data type.
    ///
    /// - precondition: Unsafe: always call from inside a performAndWait
    ///
    /// - returns: Given labels `[A, B]`, yields `[A.tr.sIDs, B.tr.sIDs, A.te.sIDs, B.te.sIDs]`
    private func unsafeBuildSampleIDArrays(sortedLabels: [SHLabel]) throws -> [[UUID]] {
        var result: [[UUID]] = []
        for dataType in [ DataType.training, DataType.testing ] {
            for coreDataLabel in sortedLabels {
                result.append(coreDataLabel.fetchUnsafeSampleUUIDs(dataType: dataType))
            }
        }
        return result
    }

    /// Given a nested array of sample ID arrays, builds a single array of sample IDs using breadth-first traversal.
    /// Applies a thumbnail limit of 8.
    ///
    /// - returns: Given `[[1, 2, 3, 4], [5, 6, 7], [8, 9], [10], []]`, returns `[1, 5, 8, 10, 2, 6, 9, 3]`
    private func buildProjectTileThumbnailSampleIDs(sampleIDArrays: [[UUID]]) -> [UUID] {
        let thumbnailLimit = 8

        // Grab 1 at a time from each list until we can complete an array of UUIDs.
        var result: [UUID] = []
        for j in 0..<thumbnailLimit {

            // Check the j'th index of each sample array.
            for sampleIDList in sampleIDArrays {
                if j >= sampleIDList.count {
                    continue
                }

                result.append(sampleIDList[j])

                if result.count >= thumbnailLimit {
                    return result
                }
            }
        }

        return result
    }

    /// Fetch a managed project with the given ID.
    ///
    /// - precondition: Unsafe: always call from inside a performAndWait
    ///
    /// - Parameter id: ID of project.
    /// - Returns: Managed project.
    private func unsafeFetchCoreDataProject(id: UUID) throws -> SHSingleLabelClassifierProject {
        let predicate = Predicate(type: .equalTo(id.uuidString), key: "id")
        let request = SHSingleLabelClassifierProject.fetchRequest()

        request.predicate = NSPredicate(predicate: predicate)
        request.fetchLimit = 1

        let projects = try self.coreDataStack.context.fetch(request)

        guard let requestedProject = projects.first else { throw DatabaseStorageServiceError.projectNotFound(id) }
        return requestedProject
    }

    /// Fetch all sorted core data projects.
    ///
    /// - precondition: Unsafe: always call from inside a performAndWait
    ///
    /// - Returns: All managed projects.
    private func unsafeFetchAllCoreDataProjects() throws -> [SHSingleLabelClassifierProject] {
        let request = SHSingleLabelClassifierProject.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SHSingleLabelClassifierProject.creationDate, ascending: false)
        ]
        let result = try self.coreDataStack.context.fetch(request)
        return result
    }

    /// Create a default label using the index in `1...defaultLabelCount` as a parameter.
    ///
    /// - precondition: Unsafe: always call from inside a performAndWait
    ///
    /// - Parameter index: Index
    /// - Returns: Default label.
    private func unsafeCreateDefaultLabel(index: Int) -> SHLabel {
        let label = SHLabel(context: coreDataStack.context)
        label.id = UUID().uuidString
        label.creationDate = Date()
        label.labelString = String(localized: .labelNumbered(index.formatted()))
        return label
    }

    /// Build a app facing project from a CoreData managed project
    ///
    /// - precondition: Unsafe: always call from inside a performAndWait
    ///
    /// - Parameter managedProject: CoreData managed object.
    /// - Returns: App facing project.
    private func unsafeBuildProject(from managedProject: SHSingleLabelClassifierProject) -> Project {
        guard let projectID = ProjectID(uuidString: managedProject.id!) else {
            fatalError("Failed to get project for id")
        }

        let shareState: Project.ShareState
        do {
            if let share = try fetchShare(projectID: projectID) {
                shareState = share.currentUserIsOwner ? .shareOwner : .shareRecipient
            } else {
                shareState = .notShared
            }
        } catch {
            os_log(.error, "Error occurred fetching share: \(error)")
            shareState = .unknown
        }

        let labelNames = (managedProject.labels?.allObjects as? [SHLabel] ?? [])
            .compactMap { $0.labelString }
            .sorted()
        return Project(
            id: projectID,
            title: managedProject.title!,
            createdAt: managedProject.creationDate!,
            shareState: shareState,
            labelNames: labelNames
        )
    }
}

extension SHSingleLabelClassifierProject {
    var unsafeSortedLabels: [SHLabel] {
        labels?.sortedArray(using: [
            NSSortDescriptor(keyPath: \SHLabel.creationDate, ascending: true)
        ]) as? [SHLabel] ?? []
    }
}

fileprivate extension LabelAnnotation {
    init?(unsafeCoreDataLabel coreDataLabel: SHLabel, projectID: ProjectID) {
        guard let labelIDString = coreDataLabel.id,
              let labelUUID = UUID(uuidString: labelIDString),
              let labelString = coreDataLabel.labelString else {
            return nil
        }
        let labelID = LabelID(id: labelUUID, projectID: projectID)
        self = LabelAnnotation(labelID: labelID,
                               label: labelString)
    }
}

/// Extension facilitating in-band fetch of all sample IDs corresponding to a particular Core Data label.
fileprivate extension SHLabel {

    /// Given a data type (train or test), fetch the sorted array of UUIDs for samples associated with the receiver.
    func fetchUnsafeSampleUUIDs(dataType: DataType, limit: Int? = nil) -> [UUID] {
        guard let id else {
            return []
        }
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "SHSingleLabelSample")
        fetchRequest.propertiesToFetch = [ "id", "creationDate", "modificationDate" ]
        if let limit {
            fetchRequest.fetchLimit = limit
        }

        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                NSPredicate(format: "label.id == %@", id),
                NSPredicate(predicate: Predicate(
                    type: .equalTo(dataType.rawValue),
                    key: "purpose"
                ))
            ])

        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \SHSingleLabelSample.modificationDate, ascending: false),
            NSSortDescriptor(keyPath: \SHSingleLabelSample.creationDate, ascending: false)
        ]
        fetchRequest.resultType = .dictionaryResultType

        do {
            if let result = try managedObjectContext?.fetch(fetchRequest) as? [NSDictionary] {
                return result.compactMap { UUID(dictionary: $0) }
            }
            os_log(.error, "Couldn't fetch!")
        } catch {
            os_log(.error, "Couldn't fetch: \(error)")
        }

        return []
    }
}

/// Extension facilitating UUID initialization from a dictionary.
fileprivate extension UUID {

    /// Initializes a UUID from a dictionary which may contain a UUID string for the key "id", if possible.
    init?(dictionary: NSDictionary) {
        guard let uuidString = dictionary["id"] as? String else {
            return nil
        }
        guard let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self = uuid
    }
}

/// Extension facilitating construction.
private extension ProjectTileViewState {

    /// Initializes the receiver with the given project, sample IDs, and total sample count.
    init(project: Project, thumbnailSampleIDs: [UUID], totalSampleCount: Int) {
        let requiredThumbnailCount = 8

        var thumbnails: [ThumbnailType] = thumbnailSampleIDs.map { .image($0) }

        // Add placeholders for diff.
        if thumbnails.count < requiredThumbnailCount {
            let diff = requiredThumbnailCount - thumbnails.count
            thumbnails.append(
                contentsOf: Array(repeating: .placeholder, count: diff)
            )
        }

        self = ProjectTileViewState(
            project: project,
            thumbnails: thumbnails,
            totalSampleCount: totalSampleCount)
    }
}
