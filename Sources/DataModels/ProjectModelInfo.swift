// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

/// Represents a snapshot of project model info when training was completed, or the project model info that _will_ be
/// used to generate a **new** model.
struct ProjectModelInfo: Codable {
    enum Change: Equatable {
        case labelAdded(labelString: String)
        case labelDeleted(labelString: String)
        case labelRenamed(oldLabelString: String, newLabelString: String)
        case samplesChanged(addedSampleCount: Int, removedSampleCount: Int, labelString: String)
    }

    /// The version of this project model info.
    let version: String

    /// The labels as they were when the model was trained.
    ///
    /// May be compared against current labels to detect labels that have been added, renamed, or deleted.
    let labels: [LabelAnnotation]

    /// The sample IDs in each label as they were when the model was trained.
    ///
    /// May be compared against the current sample IDs for each label to detect samples that have been added or deleted.
    var sampleIDsByLabelUUID: [UUID: [UUID]]

    /// The test sample IDs in each label.
    var testSampleIDsByLabelUUID: [UUID: [UUID]]
}

/// Extension facilitating decoding of on-disk model info.
extension ProjectModelInfo {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // These 3 are always present.
        self.version = try container.decode(String.self, forKey: .version)
        self.labels = try container.decode([LabelAnnotation].self, forKey: .labels)
        self.sampleIDsByLabelUUID = try container.decode([UUID: [UUID]].self, forKey: .sampleIDsByLabelUUID)

        // This one may be absent if loading an older model from disk. If absent, default to an empty dictionary.
        self.testSampleIDsByLabelUUID = try container.decodeIfPresent([UUID: [UUID]].self,
                                                                      forKey: .testSampleIDsByLabelUUID) ?? [:]
    }
}

/// Extension facilitating saving the model info to disk.
extension ProjectModelInfo {
    func write(to url: URL, with fileManager: FileManager = FileManager.default) {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(self)

            // Note: this call replaces the file automatically if one exists.
            fileManager.createFile(atPath: url.path, contents: data)

        } catch {
            os_log(.error, "Failed to save project model info: \(error)")
        }
    }

    init?(loadedFrom url: URL, with fileManager: FileManager = FileManager.default) {
        let jsonDecoder = JSONDecoder()
        do {
            guard let data = fileManager.contents(atPath: url.path()) else {
                return nil
            }
            let modelInfo = try jsonDecoder.decode(Self.self, from: data)
            self = modelInfo

        } catch {
            os_log(.error, "Failed to load project model info: \(error)")
            return nil
        }
    }

    /// The total sample count in this project model info instance.
    var sampleCount: Int {
        sampleIDsByLabelUUID.values.flatMap({ $0 }).count
    }
}

/// Extension facilitating change derivation.
extension ProjectModelInfo {

    func changes(since other: ProjectModelInfo) -> [ProjectModelInfo.Change] {
        return labelAddedChanges(since: other)
                + labelDeletedChanges(since: other)
                + labelRenameChanges(since: other)
                + sampleChanges(since: other)
    }

    private func labelAddedChanges(since other: ProjectModelInfo) -> [ProjectModelInfo.Change] {
        let addedLabelIDs = Set(labels.map(\.id)).subtracting(other.labels.map(\.id))
        let addedLabels = labels.filter {
            addedLabelIDs.contains($0.id)
        } // Sorting?
        return addedLabels.map {
            .labelAdded(labelString: $0.labelString)
        }
    }

    private func labelDeletedChanges(since other: ProjectModelInfo) -> [ProjectModelInfo.Change] {
        let deletedLabelIDs = Set(other.labels.map(\.id)).subtracting(labels.map(\.id))
        let deletedLabels = other.labels.filter {
            deletedLabelIDs.contains($0.id)
        }
        return deletedLabels.map {
            .labelDeleted(labelString: $0.labelString)
        }
    }

    private func labelRenameChanges(since other: ProjectModelInfo) -> [ProjectModelInfo.Change] {
        let commonLabelIDs = Set(labels.map(\.id)).union(Set(other.labels.map(\.id)))
        let commonLabels = labels.filter {
            commonLabelIDs.contains($0.id)
        }
        var result: [ProjectModelInfo.Change] = []

        for label in commonLabels {
            let oldLabel = other.labels.first { $0.id == label.id }
            guard let oldLabelString = oldLabel?.labelString else {
                continue
            }
            if label.matches(labelString: oldLabelString) {
                continue
            }
            result.append(.labelRenamed(oldLabelString: oldLabelString, newLabelString: label.labelString))
        }

        return result
    }

    private func sampleChanges(since other: ProjectModelInfo) -> [ProjectModelInfo.Change] {
        let commonLabelIDs = Set(labels.map(\.id)).union(Set(other.labels.map(\.id)))
        let commonLabels = labels.filter {
            commonLabelIDs.contains($0.id)
        }

        var result: [ProjectModelInfo.Change] = []

        for label in commonLabels {
            let labelUUID = label.id.id
            guard let newSampleIDs = sampleIDsByLabelUUID[labelUUID],
                  let oldSampleIDs = other.sampleIDsByLabelUUID[labelUUID] else {
                continue
            }

            let addedSampleCount = Set(newSampleIDs).subtracting(oldSampleIDs).count
            let removedSampleCount = Set(oldSampleIDs).subtracting(newSampleIDs).count

            if addedSampleCount > 0 || removedSampleCount > 0 {
                result.append(.samplesChanged(addedSampleCount: addedSampleCount,
                                              removedSampleCount: removedSampleCount,
                                              labelString: label.labelString))
            }
        }

        return result
    }
}

extension ProjectModelInfo.Change: Identifiable {
    var id: String {
        switch self {
        case let .labelAdded(labelString):
            return "Label-added-\(labelString)"
        case let .labelDeleted(labelString):
            return "Label-deleted-\(labelString)"
        case let .labelRenamed(oldLabelString, newLabelString):
            return "Label-renamed-\(oldLabelString)-to-\(newLabelString)"
        case let .samplesChanged(_, _, labelString):
            return "Samples-changed-in\(labelString)"
        }
    }
}

#if DEBUG

extension [ProjectModelInfo.Change] {
    static let fakeProjectChanges: Self = [
        .labelRenamed(oldLabelString: "Tangerine", newLabelString: "Orange"),
        .labelDeleted(labelString: "Banana"),
        .labelAdded(labelString: "Cherry"),
        .samplesChanged(addedSampleCount: 7, removedSampleCount: 0, labelString: "Cherry"),
        .samplesChanged(addedSampleCount: 1, removedSampleCount: 0, labelString: "Pear"),
        .samplesChanged(addedSampleCount: 4, removedSampleCount: 1, labelString: "Orange"),
        .samplesChanged(addedSampleCount: 1, removedSampleCount: 3, labelString: "Cucumber"),
        .samplesChanged(addedSampleCount: 0, removedSampleCount: 2, labelString: "Apple"),
        .samplesChanged(addedSampleCount: 0, removedSampleCount: 1, labelString: "Carrot")
    ]
}

extension ProjectModelInfo {
    static let fake: Self = .init(
        version: "1.0",
        labels: .fakeLabels,
        sampleIDsByLabelUUID: .fakeTrainingSamplesByLabelUUID,
        testSampleIDsByLabelUUID: .fakeTestSamplesByLabelUUID
    )
}

extension [UUID: [UUID]] {
    static var fakeTrainingSamplesByLabelUUID: Self = [
        .fakeAppleLabelUUID: [
            .fakeApple1SampleUUID,
            .fakeApple2SampleUUID,
            .fakeApple3SampleUUID
        ],
        .fakeBananaLabelUUID: [
            .fakeBanana1SampleUUID,
            .fakeBanana2SampleUUID,
            .fakeBanana3SampleUUID
        ],
        .fakeCarrotLabelUUID: [
            .fakeCarrot1SampleUUID
        ]
    ]

    static var fakeTestSamplesByLabelUUID: Self = [
        .fakeAppleLabelUUID: [
            .fakeApple4SampleUUID,
            .fakeApple5SampleUUID,
            .fakeApple6SampleUUID
        ],
        .fakeBananaLabelUUID: [
            .fakeBanana4SampleUUID,
            .fakeBanana5SampleUUID,
            .fakeBanana6SampleUUID,
        ],
        .fakeCarrotLabelUUID: []
    ]
}

#endif
