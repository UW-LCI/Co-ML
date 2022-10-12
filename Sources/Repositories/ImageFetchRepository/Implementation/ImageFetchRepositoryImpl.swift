// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import UIKit

actor ImageFetchRepositoryImpl: ImageFetchRepository {
    private let databaseStorageService: DatabaseStorageService

    private let sampleImageCache = NSCache<NSUUID, UIImage>()

    init(databaseStorageService: DatabaseStorageService) {
        self.databaseStorageService = databaseStorageService
    }

    // MARK: - ImageFetchRepository

    func fetchImage(sampleUUID: UUID) async throws -> UIImage {
        let sampleNSUUID = NSUUID(uuidString: sampleUUID.uuidString)!

        if let sampleImage = sampleImageCache.object(forKey: sampleNSUUID) {
            return sampleImage
        }

        var result: UIImage!
        let dt = try ContinuousClock().measure {

            let sample = try databaseStorageService.fetchSample(sampleID: sampleUUID)

            guard let image = UIImage(data: sample.sampleData) else {
                throw ImageFetchRepositoryError.failedToDecodeSample(sampleUUID)
            }

            sampleImageCache.setObject(image, forKey: sampleNSUUID)

            result = image
        }

        os_log(.debug, "Done fetching a single image after \(dt).")

        return result
    }
}
