// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// A labeled image ID, which joins a sample ID to a label via its Label ID.
struct LabeledImageID: Codable, Identifiable, Equatable, Hashable {
    var sampleID: UUID
    var labelID: LabelID

    /// Used for creating a _new_ labeled image ID associated with a particular label.
    init(labelID: LabelID) {
        self.sampleID = UUID()
        self.labelID = labelID
    }

    /// Used for initializing an existing LabeledImageID, for example when passing up an image from storage.
    init(existingSampleID: UUID, labelID: LabelID) {
        self.sampleID = existingSampleID
        self.labelID = labelID
    }

    /// Used for updating an existing LabeledImageID with a new associated label.
    init(existingSampleID: UUID, newLabelID: LabelID) {
        self.sampleID = existingSampleID
        self.labelID = newLabelID
    }

    var idString: String {
        sampleID.uuidString
    }

    var projectID: ProjectID {
        labelID.projectID
    }

    // MARK: - Identifiable

    var id: UUID {
        sampleID
    }
}

#if DEBUG

extension LabeledImageID {
    static let fakeApple1id = LabeledImageID(existingSampleID: .fakeApple1SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple2id = LabeledImageID(existingSampleID: .fakeApple2SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple3id = LabeledImageID(existingSampleID: .fakeApple3SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple4id = LabeledImageID(existingSampleID: .fakeApple4SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple5id = LabeledImageID(existingSampleID: .fakeApple5SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple6id = LabeledImageID(existingSampleID: .fakeApple6SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple7id = LabeledImageID(existingSampleID: .fakeApple7SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple8id = LabeledImageID(existingSampleID: .fakeApple8SampleUUID, labelID: .fakeAppleLabelID)
    static let fakeApple9id = LabeledImageID(existingSampleID: .fakeApple9SampleUUID, labelID: .fakeAppleLabelID)

    static let fakeBanana1id = LabeledImageID(existingSampleID: .fakeBanana1SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana2id = LabeledImageID(existingSampleID: .fakeBanana2SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana3id = LabeledImageID(existingSampleID: .fakeBanana3SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana4id = LabeledImageID(existingSampleID: .fakeBanana4SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana5id = LabeledImageID(existingSampleID: .fakeBanana5SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana6id = LabeledImageID(existingSampleID: .fakeBanana6SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana7id = LabeledImageID(existingSampleID: .fakeBanana7SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana8id = LabeledImageID(existingSampleID: .fakeBanana8SampleUUID, labelID: .fakeBananaLabelID)
    static let fakeBanana9id = LabeledImageID(existingSampleID: .fakeBanana9SampleUUID, labelID: .fakeBananaLabelID)

    static let fakeCarrot1id = LabeledImageID(existingSampleID: .fakeCarrot1SampleUUID, labelID: .fakeCarrotLabelID)
}

extension UUID {
    static let fakeApple1SampleUUID = UUID(uuidString: "d5613003-d33f-458b-9450-b16df2b2093d")!
    static let fakeApple2SampleUUID = UUID(uuidString: "73c022bd-0491-414a-b47b-8d353f585a7d")!
    static let fakeApple3SampleUUID = UUID(uuidString: "58121740-abaf-44d1-bf14-28d2744467e2")!
    static let fakeApple4SampleUUID = UUID(uuidString: "7aac80a9-d4ec-40b8-ada4-1ea030418d6b")!
    static let fakeApple5SampleUUID = UUID(uuidString: "e2fdb2d8-a379-463a-a95f-2d49e06e6425")!
    static let fakeApple6SampleUUID = UUID(uuidString: "08ae998d-7b6c-48c8-b6e0-3a578cc0698c")!
    static let fakeApple7SampleUUID = UUID(uuidString: "5724bcf4-eca2-491f-8f07-a70add6ec1ad")!
    static let fakeApple8SampleUUID = UUID(uuidString: "809d1f1d-9974-4290-9ee0-4dffc949d608")!
    static let fakeApple9SampleUUID = UUID(uuidString: "44307dd7-02bb-4278-9576-b1311b3cff94")!

    static let fakeBanana1SampleUUID = UUID(uuidString: "91a6477f-3e4f-4184-a345-fdf1366659ca")!
    static let fakeBanana2SampleUUID = UUID(uuidString: "487be224-48ed-4342-b6ce-501b00e40aad")!
    static let fakeBanana3SampleUUID = UUID(uuidString: "20686a52-cf0b-4821-b80e-9298a940600f")!
    static let fakeBanana4SampleUUID = UUID(uuidString: "32b83877-27e1-4271-922a-1013dc731f35")!
    static let fakeBanana5SampleUUID = UUID(uuidString: "2bb2a488-7e98-4e35-93e4-6291477660c3")!
    static let fakeBanana6SampleUUID = UUID(uuidString: "c604bde4-9330-4e97-9c6e-a63a89770b48")!
    static let fakeBanana7SampleUUID = UUID(uuidString: "51818961-5ce2-40ab-ad42-634242597611")!
    static let fakeBanana8SampleUUID = UUID(uuidString: "74aea5ea-c75d-4483-9ab5-132afeec1314")!
    static let fakeBanana9SampleUUID = UUID(uuidString: "c092a1f9-d393-4921-a1e9-58be3a237464")!

    static let fakeCarrot1SampleUUID = UUID(uuidString: "1e684a59-4180-4555-b0e3-2bea2afa01fa")!
}

extension [UUID] {
    static let fakeAppleUUIDs: Self = [
        .fakeApple1SampleUUID,
        .fakeApple2SampleUUID,
        .fakeApple3SampleUUID,
        .fakeApple4SampleUUID,
        .fakeApple5SampleUUID,
        .fakeApple6SampleUUID,
        .fakeApple7SampleUUID,
        .fakeApple8SampleUUID,
        .fakeApple9SampleUUID,
    ]

    static let fakeBananaUUIDs: Self = [
        .fakeBanana1SampleUUID,
        .fakeBanana2SampleUUID,
        .fakeBanana3SampleUUID,
        .fakeBanana4SampleUUID,
        .fakeBanana5SampleUUID,
        .fakeBanana6SampleUUID,
        .fakeBanana7SampleUUID,
        .fakeBanana8SampleUUID,
        .fakeBanana9SampleUUID,
    ]

    static let fakeCarrotUUIDs: Self = [
        .fakeCarrot1SampleUUID
    ]
}

#endif
