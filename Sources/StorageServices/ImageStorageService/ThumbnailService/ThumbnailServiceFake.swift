// Copyright 2026 Apple Inc. All rights reserved.


import Foundation

final class ThumbnailServiceFake: ThumbnailService {
    func fetchLabelData(
        projectID: UUID,
        dataType: DataType,
        thumbnailLimit: Int
    ) async throws -> [LabelRibbon] {
        []
    }
}
