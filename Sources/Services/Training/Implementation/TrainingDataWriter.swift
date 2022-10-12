// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

enum TrainingDataWriter {

    /// Write data to disk in the app's document directory using the provided URL.
    ///
    /// - Parameter dataset: Training data to be written to disk.
    /// - url: URL where the data will be stored.
    static func write(dataset: SingleLabelTrainingDataset,
                      to url: URL,
                      databaseStorageService: DatabaseStorageService) throws {

        let path = url.path(percentEncoded: false)
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }

        for group in dataset.sampleGroups {
            // only create a directory for labels that have samples
            if group.sampleIDs.isEmpty {
                os_log(.info, "Preparing dataset: Skipping folder for label %@", group.annotation, " with 0 images")
                continue
            }

            let annotationDirectoryURL = url.appendingPathComponent(group.annotation)

            // Create an annotation directory if one doesn't exist.
            let fileManager = FileManager.default
            try fileManager.createFolderIfNotPresent(folderURL: annotationDirectoryURL)

            for sampleID in group.sampleIDs {
                // Use an autorelease pool to ensure that each sample data is released after we finish writing it
                // to disk.
                _ = try autoreleasepool {
                    let sampleURL = annotationDirectoryURL
                        .appendingPathComponent("\(group.annotation)-\(sampleID)")
                        .appendingPathExtension(try dataset.mediaType.fileNameExtension())
                    os_log(.debug, "Writing a sample to URL \(sampleURL)")
                    let sample = try databaseStorageService.fetchSample(sampleID: sampleID)
                    try sample.sampleData.write(to: sampleURL)
                }
            }
        }
    }
}
