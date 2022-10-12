// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct LabelID: Codable, Identifiable, Equatable, Hashable, CustomStringConvertible {
    let id: UUID
    let projectID: ProjectID

    var idString: String {
        id.uuidString
    }

    // MARK: - CustomStringConvertible

    var description: String {
        "LabelID(id: '\(idString)', projectID: \(projectID.uuidString)"
    }
}

#if DEBUG

extension LabelID {
    static let fakeAppleLabelID = LabelID(id: .fakeAppleLabelUUID, projectID: .fakeProjectID)
    static let fakeBananaLabelID = LabelID(id: .fakeBananaLabelUUID, projectID: .fakeProjectID)
    static let fakeCarrotLabelID = LabelID(id: .fakeCarrotLabelUUID, projectID: .fakeProjectID)
}

extension UUID {
    static let fakeAppleLabelUUID = UUID(uuidString: "0a519a0e-eb63-4c58-92f3-c1e2c545f3ad")!
    static let fakeBananaLabelUUID = UUID(uuidString: "30a4e5c7-d229-46d3-a25f-f27b41fefc32")!
    static let fakeCarrotLabelUUID = UUID(uuidString: "9e2bd70c-f5b0-4d84-a828-7c9a36804576")!
}

#endif
