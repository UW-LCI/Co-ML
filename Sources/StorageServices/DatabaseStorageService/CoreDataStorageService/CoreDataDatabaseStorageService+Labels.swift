// Copyright 2026 Apple Inc. All rights reserved.

import CoreData
import Foundation
import os.log

extension CoreDataDatabaseStorageService {
    /// Delete a label with the given ID.
    ///
    /// - Parameter id: ID of label.
    func deleteLabel(id: LabelID) async throws {
        try await coreDataStack.context.perform {
            let label = try self.unsafeFetchCoreDataLabel(id: id)
            self.coreDataStack.context.delete(label)
            try self.coreDataStack.context.save()

            let projectID = id.projectID
            self.coreDataStack.fakeNotify(project: projectID)
        }
    }

    func add(label: LabelAnnotation) throws {
        try coreDataStack.context.performAndWait {
            let projectID = label.projectID
            guard let existingProject = try unsafeFetchCoreDataProject(projectID: projectID) else {
                throw DatabaseStorageServiceError.projectNotFound(projectID)
            }

            let newLabel = SHLabel(context: coreDataStack.context)
            newLabel.creationDate = Date()
            newLabel.id = label.idString
            newLabel.labelString = label.labelString
            newLabel.project = existingProject

            coreDataStack.saveContext()
            self.coreDataStack.fakeNotify(project: projectID)
        }
    }

    func fetchLabels(projectID: ProjectID) async throws -> [LabelAnnotation] {

        try coreDataStack.context.performAndWait {
            let coreDataLabels = try unsafeFetchCoreDataLabels(projectID: projectID)
            return coreDataLabels.compactMap { coreDataLabel in
                let labelID = LabelID(id: UUID(uuidString: coreDataLabel.id!)!, projectID: projectID)
                return LabelAnnotation(labelID: labelID, label: coreDataLabel.labelString ?? "FIXME")
            }
        }
    }

    func fetchLabel(labelID: LabelID) async throws -> LabelAnnotation? {

        try coreDataStack.context.performAndWait {
            let coreDataLabel = try unsafeFetchCoreDataLabel(id: labelID)

            return LabelAnnotation(labelID: labelID, label: coreDataLabel.labelString ?? "FIXME")
        }
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) throws {
        try coreDataStack.context.performAndWait {
            let coreDataLabel = try unsafeFetchCoreDataLabel(id: labelID)
            coreDataLabel.labelString = newLabelString
            try coreDataStack.context.save()

            let projectID = labelID.projectID
            self.coreDataStack.fakeNotify(project: projectID)
        }
    }

    func fetchLabelSampleCount(id: LabelID) async throws -> Int {
        try coreDataStack.context.performAndWait {
            let coreDataLabel = try unsafeFetchCoreDataLabel(id: id)
            return coreDataLabel.samples?.count ?? 0
        }
    }

    func fetchLabelSampleCount(id: LabelID, dataType: DataType) async throws -> Int {
        try coreDataStack.context.performAndWait {
            let coreDataLabel = try unsafeFetchCoreDataLabel(id: id)

            let dataTypePredicate = Predicate(
                type: .equalTo(dataType.rawValue),
                key: "purpose"
            )
            let filterPredicate = NSPredicate(predicate: dataTypePredicate)

            return coreDataLabel.samples?.filtered(using: filterPredicate).count ?? 0
        }
    }

    /// Fetch metadata for the labels associated with a project.
    ///
    /// - Parameter projectID: Project ID
    /// - Returns: Labels' metadata
    func fetchLabelMetadata(projectID: UUID) throws -> [LabelMetadata] {
        try coreDataStack.context.performAndWait {
            let coreDataLabels = try unsafeFetchCoreDataLabels(projectID: projectID)

            return coreDataLabels.map {
                LabelMetadata(name: $0.labelString!,
                         id: LabelID(id: UUID(uuidString: $0.id!)!, projectID: projectID),
                         createdAt: $0.creationDate!)
            }
        }
    }

    // MARK: - Private

    /// fetch a Label ManagedObject
    /// - precondition: Unsafe: always call from inside a performAndWait
    func unsafeFetchCoreDataLabel(id: LabelID) throws -> SHLabel {
        let labelFetchRequest = SHLabel.fetchRequest()
        labelFetchRequest.fetchLimit = 1
        labelFetchRequest.predicate = NSPredicate(
            predicate: Predicate(type: .equalTo(id.idString), key: "id")
        )
        let fetchResult = try coreDataStack.context.fetch(labelFetchRequest)

        guard let label = fetchResult.first else {
            throw DatabaseStorageServiceError.labelNotFound(id)
        }
        return label
    }

    /// fetch all Label ManagedObjects
    /// - precondition: Unsafe: always call from inside a performAndWait
    func unsafeFetchCoreDataLabels(projectID: ProjectID) throws -> [SHLabel] {
        guard let existingProject = try unsafeFetchCoreDataProject(projectID: projectID) else {
            throw DatabaseStorageServiceError.projectNotFound(projectID)
        }
        return existingProject.unsafeSortedLabels
    }
}
