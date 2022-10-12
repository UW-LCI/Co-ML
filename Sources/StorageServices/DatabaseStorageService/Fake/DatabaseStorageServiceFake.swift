// Copyright 2026 Apple Inc. All rights reserved.

#if DEBUG

import CloudKit
import CoreData
import Foundation
import UIKit

extension DatabaseStorageService where Self == DatabaseStorageServiceFake {
    static var fake: DatabaseStorageServiceFake { ._fake }
}

extension DatabaseStorageServiceFake {
    fileprivate nonisolated static var _fake: Self { Self() }
}

extension DatabaseStorageServiceFake: @unchecked Sendable {}

final class DatabaseStorageServiceFake: DatabaseStorageService {
    var projectsByID: [UUID: Project] = [:]
    var samplesByLabelID: [LabelID: [AnnotatedSample]]
    var labels: [LabelAnnotation]

    init(projectsByID: [UUID: Project] = [:],
         samplesByLabelID: [LabelID: [AnnotatedSample]] = [:],
         labels: [LabelAnnotation] = []) {
        self.projectsByID = projectsByID
        self.samplesByLabelID = samplesByLabelID
        self.labels = labels
    }

    init(projects: [Project],
         samplesByLabelID: [LabelID: [AnnotatedSample]] = [:],
         labels: [LabelAnnotation] = []) {
        self.projectsByID = Dictionary(
            uniqueKeysWithValues: projects
                .map { project in (project.id, project) }
            )
        self.samplesByLabelID = samplesByLabelID
        self.labels = labels
    }

    func fetchProjectTitle(id: UUID) async throws -> String {
        guard let title = projectsByID[id]?.title else {
            throw DatabaseStorageServiceError.projectNotFound(id)
        }
        return title
    }

    func create(project: Project) async throws {
        projectsByID[project.id] = project
    }

    func fetchProject(projectID: ProjectID) async throws -> Project {
        Array(projectsByID.values)[0]
    }

    func fetchProjects() async throws -> [Project] {
        Array(projectsByID.values)
    }

    func fetchLabelSampleCount(id: LabelID) async throws -> Int {
        0
    }

    func fetchLabelSampleCount(id: LabelID, dataType: DataType) async throws -> Int {
        0
    }

    func fetchSamples(labelID: LabelID, datatype: DataType, limit: Int) async throws -> [Sample] {
        []
    }

    func fetchLabelData(using metadata: [LabelMetadata], thumbnailLimit: Int, dataType: DataType) async throws -> [LabelData] {
        []
    }

    func fetchLabelMetadata(projectID: UUID) async throws -> [LabelMetadata] {
        []
    }

    func delete(projectID: ProjectID, isOnline: Bool) async throws {
        projectsByID.removeValue(forKey: projectID)
    }

    func delete(projectIDs: Set<ProjectID>, isOnline: Bool) async throws {
        for projectID in projectIDs {
            try await delete(projectID: projectID, isOnline: isOnline)
        }
    }

    func fetchShare(projectID: ProjectID) throws -> CKShare? {
        return nil
    }

    func initiateNewShare(projectID: ProjectID) async throws -> SharingController.SendableShareMetadata {
        throw DatabaseStorageServiceError.notAvailable
    }

    func getCKContainer() -> CKContainer {
        CKContainer(identifier: "DatabaseStorageServiceFake")
    }

    func unshareSharedProject(projectID: UUID, share: CKShare) throws {
        // No-op
    }

    // MARK: - Label
    func add(label: LabelAnnotation) async throws {
        // No-op
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        // No-op
    }

    func fetchLabels(projectID: ProjectID) async throws -> [LabelAnnotation] {
        if !labels.isEmpty {
            return labels
        }
        return Constants.annotations[projectID.uuidString] ?? []
    }

    func fetchLabel(labelID: LabelID) async throws -> LabelAnnotation? {
        nil
    }

    // MARK: - Samples
    func add(labeledImage: LabeledImage) async throws {
        // No-op
    }

    func add(labeledImages: [LabeledImage]) async throws {
        // No-op
    }

    func fetchSamples(labelID: LabelID, dataType: DataType) async throws -> [AnnotatedSample] {
        if let samples = samplesByLabelID[labelID] {
            return samples
        }
        if let annotation = Constants.annotations[labelID.projectID.uuidString]?.first {
            return Constants.samples[annotation.labelString] ?? []
        }
        return []
    }

    func fetchSample(sampleID: UUID) throws -> AnnotatedSample {
        var allSamples: [AnnotatedSample] = []
        for sampleArray in Array(samplesByLabelID.values) {
            allSamples.append(contentsOf: sampleArray)
        }
        guard let result = allSamples.first(where: { $0.id == sampleID }) else {
            throw DatabaseStorageServiceError.sampleNotFound(sampleID)
        }
        return result
    }

    func deleteSample(sampleID: UUID) async throws {
        var matchingLabelID: LabelID?
        var filteredSamples: [AnnotatedSample]?
        for (labelID, samples) in samplesByLabelID {
            // swiftlint:disable:next for_where
            if samples.first(where: { $0.id == sampleID }) != nil {
                matchingLabelID = labelID
                filteredSamples = samples.filter { $0.id != sampleID }
                break
            }
        }
        if let matchingLabelID {
            samplesByLabelID[matchingLabelID] = filteredSamples
        }
    }

    func moveSample(sampleID: UUID, toDataType: DataType) throws {
        throw DatabaseStorageServiceError.notAvailable
    }

    func moveSample(sampleID: UUID, toLabelWithID labelID: LabelID) async throws {
        let sample = try await fetchSample(sampleID: sampleID)
        try await deleteSample(sampleID: sampleID)
        samplesByLabelID[labelID, default: []].append(sample)
    }

    func renameProject(id: UUID, newName: String) async throws {
        guard var project = projectsByID[id] else { throw DatabaseStorageServiceError.projectNotFound(id) }
        project.title = newName

        projectsByID[id] = project
    }

    func deleteLabel(id: LabelID) async throws {
        labels.removeAll(where: { $0.id == id })
    }

    func fetchProjectModelInfo(projectID: ProjectID) throws -> ProjectModelInfo {
        if projectsByID[projectID] == nil || labels.isEmpty {
            throw DatabaseStorageServiceError.projectNotFound(projectID)
        }
        var sampleIDsByLabelUUID: [UUID: [UUID]] = [:]
        for (labelID, samples) in samplesByLabelID {
            sampleIDsByLabelUUID[labelID.id] = samples.map { $0.id }
        }
        return ProjectModelInfo(version: "1.1",
                                labels: labels,
                                sampleIDsByLabelUUID: sampleIDsByLabelUUID,
                                testSampleIDsByLabelUUID: [:])
    }

    func fetchProjectTileViewStates() throws -> [ProjectTileViewState] {
        let sortedProjects = projectsByID.values.sorted { $0.createdAt > $1.createdAt }
        let result = sortedProjects.map { ProjectTileViewState(project: $0, thumbnails: [], totalSampleCount: 0) }
        return result
    }
}

private struct Constants {
    // ProjectID to annotation.
    static let annotations: [String: [LabelAnnotation]] = [
        "19517F87-DCAB-4C6D-976A-9A60BCB0D74B": [ // Clarendon
            LabelAnnotation(
                label: "pencil",
                projectID: UUID(uuidString: "19517F87-DCAB-4C6D-976A-9A60BCB0D74B")!
            ),
        ],
        "B59A7CA7-224C-44E7-AE7C-02E9B1719FEB": [ // Manchester
            LabelAnnotation(
                label: "arrow",
                projectID: UUID(uuidString: "B59A7CA7-224C-44E7-AE7C-02E9B1719FEB")!
            )
        ]
    ]

    static let samples: [String: [AnnotatedSample]] = [
        "arrow": [
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "arrow", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "square.and.arrow.up")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            )
        ],
        "pencil": [
            AnnotatedSample(
                annotation: LabelAnnotation(label: "pencil", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "pencil.circle")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "pencil", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "pencil.circle")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            ),
            AnnotatedSample(
                annotation: LabelAnnotation(label: "pencil", projectID: UUID()),
                sampleType: .image,
                sampleData: UIImage(systemName: "pencil.circle")!.jpegData(compressionQuality: 1.0)!,
                creationDate: Date()
            )
        ]
    ]
}

#endif
