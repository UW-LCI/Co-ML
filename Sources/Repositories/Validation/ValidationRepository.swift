// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit

/// A repository that allows labeled images to be validated.
protocol ValidationRepository: Actor {

    /// The project ID for which this service provides validation.
    var projectID: ProjectID { get }

    /// Whether any model exists for this project.
    func loadModel() async throws

    /// Unloads the current model.
    func unloadModel() async

    /// Given a labeled image, attempts to classify that image.
    func classify(labeledImage: LabeledImage) async throws -> Prediction
}
