// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

#if DEBUG

actor ImageFetchRepositoryFake: ImageFetchRepository {
    static let fakeImages: [LabeledImage] = [
        .fakeApple1,
        .fakeApple2,
        .fakeApple3,
        .fakeApple4,
        .fakeApple5,
        .fakeApple6,
        .fakeApple7,
        .fakeApple8,
        .fakeApple9,
        .fakeBanana1,
        .fakeBanana2,
        .fakeBanana3,
        .fakeBanana4,
        .fakeBanana5,
        .fakeBanana6,
        .fakeBanana7,
        .fakeBanana8,
        .fakeBanana9,
    ]

    static func fetchImage(_ sampleUUID: UUID) async throws -> UIImage {
        if let result = fakeImages.first(where: { $0.id.id == sampleUUID }) {
            return result.image
        }
        throw DatabaseStorageServiceError.sampleNotFound(sampleUUID)
    }

    private var imagesBySampleID: [UUID: UIImage]

    init(imagesBySampleID: [UUID: UIImage] = [:]) {
        self.imagesBySampleID = imagesBySampleID
    }

    func fetchImage(sampleUUID: UUID) async throws -> UIImage {
        if let result = imagesBySampleID[sampleUUID] {
            return result
        }
        return try await Self.fetchImage(sampleUUID)
    }
}

#endif
