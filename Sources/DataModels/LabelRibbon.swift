// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct LabelRibbon: Sendable {
    var totalSampleCount: Int
    var metadata: LabelMetadata
    var images: [LabeledImage]

    var labelID: LabelID {
        metadata.id
    }

    var labelName: String {
        metadata.name
    }
}

struct LabelData: Sendable {
    var totalSampleCount: Int // Images might might have been fetched with a limit.
    var metadata: LabelMetadata
    var images: [Sample]

    var labelID: LabelID {
        metadata.id
    }

    var labelName: String {
        metadata.name
    }
}

struct LabelMetadata: Sendable {
    var name: String
    var id: LabelID
    var createdAt: Date
}

struct Sample: Sendable {
    var data: Data
    var creationDate: Date
    var dataType: String
    var id: String
}
