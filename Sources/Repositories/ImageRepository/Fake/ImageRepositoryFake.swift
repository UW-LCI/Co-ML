// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

#if DEBUG

actor ImageRepositoryFake: ImageRepository {
    let projectID: ProjectID

    init(
        projectID: ProjectID,
        labels: [LabelAnnotation] = [],
        imagesByLabel: [LabelID: [LabeledImage]] = [:]
    ) {
        self.projectID = projectID
        self.labels = labels
        self.imagesByLabel = imagesByLabel
    }

    private var labels: [LabelAnnotation]
    private var imagesByLabel: [LabelID: [LabeledImage]]

    func add(label: LabelAnnotation) async throws {
        labels.append(label)
    }

    func add(labeledImage: LabeledImage) async throws {
        imagesByLabel[labeledImage.labelID, default: []].append(labeledImage)
    }

    func add(labeledImages: [LabeledImage]) async throws {
        for image in labeledImages {
            try await add(labeledImage: image)
        }
    }

    func update(labelWithID labelID: LabelID, newLabelString: String) async throws {
        fatalError("This fake doesn't support label updates.")
    }
}

extension ImageRepository where Self == ImageRepositoryFake {
    static func fake(
        projectID: ProjectID = .fakeProjectID
    ) -> Self {
        .init(
            projectID: projectID,
            labels: .fakeLabels,
            imagesByLabel: .fakeImagesByLabel
        )
    }
}

#endif
