// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/** A label, used for image classifiers. */
struct LabelAnnotation: Codable, Identifiable, Equatable, Hashable, CustomStringConvertible {
    let id: LabelID
    var labelString: String

    init(labelID: LabelID, label: String) {
        self.id = labelID
        self.labelString = label
    }

    init(label: String, projectID: ProjectID) {
        self.id = LabelID(id: UUID(), projectID: projectID)
        self.labelString = label
    }

    init(existingAnnotation: LabelAnnotation, updatedString: String) {
        self.id = existingAnnotation.id
        self.labelString = updatedString
    }

    func matches(labelString: String) -> Bool {
        self.labelString == labelString
    }

    // MARK: - Computed properties

    var idString: String {
        id.idString
    }

    var projectID: ProjectID {
        id.projectID
    }

    // MARK: - CustomStringConvertible

    var description: String {
        "'\(labelString)', \(id)"
    }
}

#if DEBUG

extension [LabelAnnotation] {
    static let fakeLabels: Self = [
        .fakeAppleLabel,
        .fakeBananaLabel,
        .fakeCarrotLabel
    ]
}

extension LabelAnnotation {
    static let fakeAppleLabel = LabelAnnotation(labelID: .fakeAppleLabelID, label: .fakeAppleLabelString)
    static let fakeBananaLabel = LabelAnnotation(labelID: .fakeBananaLabelID, label: .fakeBananaLabelString)
    static let fakeCarrotLabel = LabelAnnotation(labelID: .fakeCarrotLabelID, label: .fakeCarrotLabelString)
}

extension String {
    static let fakeAppleLabelString = "Apple"
    static let fakeBananaLabelString = "Banana"
    static let fakeCarrotLabelString = "Carrot"
}

#endif
