// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

protocol ImageRepository {

    var projectID: ProjectID { get }

    /// Adds a new empty label.
    func add(label: LabelAnnotation) async throws

    /// Adds the given labeled image.
    func add(labeledImage: LabeledImage) async throws

    /// Adds the given labeled images.
    func add(labeledImages: [LabeledImage]) async throws

    /// Updates the specified label string.
    func update(labelWithID labelID: LabelID, newLabelString: String) async throws
}
