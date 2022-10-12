// Copyright 2026 Apple Inc. All rights reserved.

import CoreData
import Foundation
import os.log
import UIKit
import UniformTypeIdentifiers

extension CoreDataDatabaseStorageService {
    func add(labeledImage: LabeledImage) async throws {
        try await add(labeledImages: [labeledImage])
    }

    func add(labeledImages: [LabeledImage]) async throws {
        try coreDataStack.context.performAndWait {
            guard let firstLabeledImage = labeledImages.first else {
                // Adding zero images is a no-op.
                return
            }
            let firstLabelID = firstLabeledImage.labelID
            let projectID = firstLabelID.projectID
            if let otherLabelImage = labeledImages.first(where: { $0.labelID != firstLabelID }) {
                throw DatabaseStorageServiceError.cantBatchAddToMultipleLabels(firstLabelID, otherLabelImage.labelID)
            }

            let existingLabel = try unsafeFetchCoreDataLabel(id: firstLabelID)

            for labeledImage in labeledImages {

                let newSample = SHSingleLabelSample(context: coreDataStack.context)
                newSample.id = labeledImage.idString
                newSample.creationDate = labeledImage.creationDate
                newSample.sampleDataType = UTType.jpeg.identifier
                newSample.sampleData = labeledImage.image.jpegData(compressionQuality: 1.0)
                newSample.purpose = labeledImage.dataType.purposeString

                newSample.label = existingLabel
            }

            coreDataStack.saveContext()
            self.coreDataStack.fakeNotify(project: projectID)
        }
    }

    /// Fetch samples on a label, applying a limit.
    ///
    /// - Parameters:
    ///   - labelID: Label ID
    ///   - limit: Fetch limit
    ///   - datatype: Data type
    /// - Returns: Samples
    func fetchSamples(labelID: LabelID, datatype: DataType, limit: Int) async throws -> [Sample] {
        try await coreDataStack.context.perform {
            let label = try self.unsafeFetchCoreDataLabel(id: labelID)
            let labelPredicate = Predicate(type: .equalTo(label), key: "label")
            let dataTypePredicate = Predicate(
                type: .equalTo(datatype.rawValue),
                key: "purpose"
            )

            let compound = NSCompoundPredicate(
                andPredicateWithSubpredicates: [
                    NSPredicate(predicate: labelPredicate),
                    NSPredicate(predicate: dataTypePredicate)
                ]
            )
            let newToOld = NSSortDescriptor(keyPath: \SHSingleLabelSample.creationDate, ascending: false)

            let request = SHSingleLabelSample.fetchRequest()
            request.predicate = compound
            request.sortDescriptors = [newToOld]
            request.fetchLimit = limit

            let coreDataSamples = try self.coreDataStack.context.fetch(request)
            return coreDataSamples.map {
                Sample(data: $0.sampleData!,
                       creationDate: $0.creationDate!,
                       dataType: $0.sampleDataType!,
                       id: $0.id!)
            }
        }
    }

    /// Fetch data associated with a label.
    ///
    /// - Parameters:
    ///   - metadata: Label metadata
    ///   - thumbnailLimit: Thumbnail fetch limit
    ///   - dataType: Data type
    /// - Returns: Label data
    func fetchLabelData(
        using metadata: [LabelMetadata],
        thumbnailLimit: Int,
        dataType: DataType
    ) async throws -> [LabelData] {
        var labelData: [LabelData] = []
        for metadata in metadata {
            // total including both training and test
            let totalCount = try await fetchLabelSampleCount(id: metadata.id, dataType: dataType)
            let samples = try await fetchSamples(
                labelID: metadata.id,
                datatype: dataType,
                limit: thumbnailLimit
            )

            labelData.append(LabelData(
                totalSampleCount: totalCount,
                metadata: metadata,
                images: samples
            ))
        }
        return labelData
    }


    func fetchSamples(labelID: LabelID, dataType: DataType) async throws -> [AnnotatedSample] {
        try coreDataStack.context.performAndWait {

            let coreDataLabel = try unsafeFetchCoreDataLabel(id: labelID)

            let coreDataSamples = try unsafeFetchCoreDataSamples(label: coreDataLabel, labelID: labelID, dataType: dataType)

            /// This is code duplication - fix later
            let existingLabel = LabelAnnotation(labelID: labelID, label: coreDataLabel.labelString ?? "FIXME")

            return coreDataSamples.map { coreDataSample in
                AnnotatedSample(id: UUID(uuidString: coreDataSample.id!)!,
                                annotation: existingLabel,
                                sampleType: .jpeg,
                                sampleData: coreDataSample.sampleData!,
                                creationDate: coreDataSample.creationDate!)
            }
        }
    }

    func fetchSample(sampleID: UUID) throws -> AnnotatedSample {
        let context = coreDataStack.imageFetchContext
        return try context.performAndWait {
            let coreDataSample = try unsafeFetchCoreDataSample(sampleID: sampleID, context: context)

            guard let coreDataLabel = coreDataSample.label else {
                throw DatabaseStorageServiceError.sampleHasNoLabel(sampleID)
            }

            guard let labelString = coreDataLabel.labelString,
                  let labelIDString = coreDataLabel.id,
                  let labelUUID = UUID(uuidString: labelIDString),
                  let coreDataProject = coreDataLabel.project,
                  let projectIDString = coreDataProject.id,
                  let projectID = UUID(uuidString: projectIDString)
            else {
                throw DatabaseStorageServiceError.sampleNotFound(sampleID)
            }

            let labelID = LabelID(id: labelUUID, projectID: projectID)
            let existingLabel = LabelAnnotation(labelID: labelID, label: labelString)
            return AnnotatedSample(
                id: sampleID,
                annotation: existingLabel,
                sampleType: .jpeg,
                sampleData: coreDataSample.sampleData!,
                creationDate: coreDataSample.creationDate!)
        }
    }

    func deleteSample(sampleID: UUID) async throws {
        try coreDataStack.context.performAndWait {
            let coreDataSample = try unsafeFetchCoreDataSample(sampleID: sampleID)

            guard let label = coreDataSample.label,
                  let project = label.project,
                  let projectIDString = project.id,
                  let projectID = UUID(uuidString: projectIDString) else {
                os_log("Could not get projectID for sample to delete")
                return
            }
            coreDataStack.context.delete(coreDataSample)
            coreDataStack.saveContext()

            self.coreDataStack.fakeNotify(project: projectID)
        }
    }

    func moveSample(sampleID: UUID, toDataType dataType: DataType) throws {
        try coreDataStack.context.performAndWait {
            let coreDataSample = try unsafeFetchCoreDataSample(sampleID: sampleID)
            coreDataSample.purpose = dataType.purposeString
            coreDataSample.modificationDate = Date()
            coreDataStack.saveContext()
        }
    }

    func moveSample(sampleID: UUID, toLabelWithID labelID: LabelID) async throws {
        try coreDataStack.context.performAndWait {
            let coreDataSample = try unsafeFetchCoreDataSample(sampleID: sampleID)

            let destinationCoreDataLabel = try unsafeFetchCoreDataLabel(id: labelID)

            coreDataSample.label = destinationCoreDataLabel
            coreDataSample.modificationDate = Date()
            coreDataStack.saveContext()

            let projectID = labelID.projectID
            self.coreDataStack.fakeNotify(project: projectID)
        }
    }

    // - MARK: Private

    /// fetch all samples for a label
    /// - precondition: Unsafe: always call from inside a performAndWait
    func unsafeFetchCoreDataSamples(label: SHLabel, labelID: LabelID, dataType: DataType) throws -> [SHSingleLabelSample] {
        guard let samples = label.samples as? Set<SHSingleLabelSample> else {
            throw DatabaseStorageServiceError.invalidSamples(labelID)
        }
        let filteredSamples = samples.filter { dataType.matches(purpose: $0.purpose) } as NSSet
        let descriptors = [
            NSSortDescriptor(keyPath: \SHSingleLabelSample.creationDate, ascending: false)
        ]

        guard let sortedSamples = filteredSamples.sortedArray(using: descriptors) as? [SHSingleLabelSample] else {
            throw DatabaseStorageServiceError.invalidSamples(labelID)
        }
        return sortedSamples
    }

    /// fetch a sample by its ID
    /// - precondition: Unsafe: always call from inside a performAndWait
    func unsafeFetchCoreDataSample(sampleID: UUID, context: NSManagedObjectContext? = nil) throws -> SHSingleLabelSample {
        let innerContext = context ?? coreDataStack.context
        let sampleFetchRequest = SHSingleLabelSample.fetchRequest()
        sampleFetchRequest.predicate = NSPredicate(format: "id == %@", sampleID.uuidString)
        let samples = try innerContext.fetch(sampleFetchRequest)
        guard let result = samples.first else {
            throw DatabaseStorageServiceError.sampleNotFound(sampleID)
        }
        if samples.count > 1 {
            os_log(.error, "ERROR! \(samples.count) samples with ID \(sampleID)! Expected 1.")
        }
        return result
    }
}
