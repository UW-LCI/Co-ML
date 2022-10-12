// Copyright 2026 Apple Inc. All rights reserved.

import CloudKit
import CoreData
import Foundation
import UIKit

/// Database storage service protocol that must be implemented by a specific concrete service provider such as CoreData or SQLite
protocol DatabaseStorageService: Sendable {
    /// Rename a project.
    ///
    /// - Parameters:
    ///   - id: ID of project.
    ///   - newName: Project's new name.
    func renameProject(id: UUID, newName: String) async throws

    /// Creates the new project and returns a new list of projects
    /// Create API can return the updated list OR just the newly added project
    func create(project: Project) async throws

    /// Fetch a project title, given project's id.
    ///
    /// - Parameter id: Project ID
    /// - Returns: Project's title
    func fetchProjectTitle(id: UUID) async throws -> String

    /// Fetches all the current projects
    func fetchProjects() async throws -> [Project]

    /// Fetches a project's metadata, given project's id
    func fetchProject(projectID: ProjectID) async throws -> Project

    /// Deletes the project with the given ID
    func delete(projectID: ProjectID, isOnline: Bool) async throws

    /// Deletes all projects with the given IDs.
    func delete(projectIDs: Set<ProjectID>, isOnline: Bool) async throws

    /// Fetches any share for the given project ID
    func fetchShare(projectID: ProjectID) throws -> CKShare?

    /// Initiates a new share for the given project ID
    func initiateNewShare(projectID: ProjectID) async throws -> SharingController.SendableShareMetadata

    /// Provides the CloudKit container
    func getCKContainer() -> CKContainer

    // MARK: - Labels

    /// Adds the given label annotation to its associated project.
    func add(label: LabelAnnotation) async throws

    /// Fetches all labels associated with the given project ID.
    func fetchLabels(projectID: ProjectID) async throws -> [LabelAnnotation]

    /// Fetches a single label with a given ID, or nil if none exists.
    func fetchLabel(labelID: LabelID) async throws -> LabelAnnotation?

    /// Updates the specified label's string.
    func update(labelWithID labelID: LabelID, newLabelString: String) async throws

    /// Delete a label with the given ID.
    ///
    /// - Parameter id: ID of label.
    func deleteLabel(id: LabelID) async throws

    // MARK: - Samples

    /// Adds the given sample to the label with the given ID.
    func add(labeledImage: LabeledImage) async throws

    /// Adds the given labeled image to the database.
    func add(labeledImages: [LabeledImage]) async throws

    /// Fetches all samples corresponding to the given label ID, with the given data type.
    func fetchSamples(labelID: LabelID, dataType: DataType) async throws -> [AnnotatedSample]

    /// Fetch metadata for the labels associated with a project.
    ///
    /// - Parameter projectID: Project ID
    /// - Returns: Labels' metadata
    func fetchLabelMetadata(projectID: UUID) async throws -> [LabelMetadata]

    /// Fetch samples on a label, applying a limit.
    ///
    /// - Parameters:
    ///   - labelID: Label ID
    ///   - limit: Fetch limit
    ///   - datatype: Data type
    /// - Returns: Samples
    func fetchSamples(labelID: LabelID, datatype: DataType, limit: Int) async throws -> [Sample]

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
    ) async throws -> [LabelData]

    /// Fetch the total sample count on a give label.
    ///
    /// - Parameter id: Label ID
    /// - Returns: Total sample count.
    func fetchLabelSampleCount(id: LabelID) async throws -> Int

    /// Fetch the total sample count on a give label and datatype.
    ///
    /// - Parameters:
    /// - id: Label ID
    /// - dataType: Data type
    /// - Returns: Total sample count.
    func fetchLabelSampleCount(id: LabelID, dataType: DataType) async throws -> Int

    /// Fetches a single sample with the given sample ID.
    func fetchSample(sampleID: UUID) throws -> AnnotatedSample

    /// Deletes a single sample with the given sample ID.
    func deleteSample(sampleID: UUID) async throws

    /// Moves the sample with the given ID to the specified data type.
    func moveSample(sampleID: UUID, toDataType: DataType) throws

    /// Moves a sample to the specified label ID.
    func moveSample(sampleID: UUID, toLabelWithID labelID: LabelID) async throws

    /// Fetches project model info for the given project ID.
    func fetchProjectModelInfo(projectID: ProjectID) throws -> ProjectModelInfo

    /// Fetches all project tile view states.
    func fetchProjectTileViewStates() throws -> [ProjectTileViewState]
}
