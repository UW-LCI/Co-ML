// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

protocol SampleStorageService: Sendable {

    /// Fetches all labels for a given project ID.
    func fetchLabels(projectID: ProjectID) async throws -> [LabelAnnotation]

    /// Fetches all image samples for a given label ID.
    func fetchSamples(labelID: LabelID, dataType: DataType) async throws -> [AnnotatedSample]

    /// Adds the given project-associated label to storage.
    func add(label: LabelAnnotation) async throws

    /// Adds the given sample.
    func add(labeledImage: LabeledImage) async throws

    /// Adds the given sample.
    func add(labeledImages: [LabeledImage]) async throws

    /// Updates the label with the given ID with the new string.
    func update(labelWithID labelID: LabelID, newLabelString: String) async throws
}

