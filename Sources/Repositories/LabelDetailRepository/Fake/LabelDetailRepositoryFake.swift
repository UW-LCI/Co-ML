// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

actor LabelDetailRepositoryFake: LabelDetailRepository {
    let labelID: LabelID
    let dataType: DataType
    private let imageIDs: [LabeledImageID]

    init(labelID: LabelID, dataType: DataType, imageIDs: [LabeledImageID] = []) {
        self.labelID = labelID
        self.dataType = dataType
        self.imageIDs = imageIDs
    }

    // MARK: - LabelDetailRepository

    func fetchImageIDs() async throws -> [LabeledImageID] {
        imageIDs
    }
}
