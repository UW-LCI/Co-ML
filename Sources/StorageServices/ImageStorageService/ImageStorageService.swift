// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

protocol ImageStorageService: Sendable {

    /// Fetches all labels for a given project ID.
    func fetchLabels(fromProjectWithID projectID: ProjectID) async throws -> [LabelAnnotation]

    /// Fetches all images for a given label ID.
    func fetchImages(withLabelID labelID: LabelID, dataType: DataType) async throws -> [LabeledImage]

    /// Adds the given label to the given project ID.
    func add(label: LabelAnnotation) async throws

    /// Adds the given image to the given label.
    func add(labeledImage: LabeledImage) async throws

    /// Adds the given images to the given label.
    func add(labeledImages: [LabeledImage]) async throws

    /// Updates the label with the given ID with the new string.
    func update(labelWithID labelID: LabelID, newLabelString: String) async throws
}
