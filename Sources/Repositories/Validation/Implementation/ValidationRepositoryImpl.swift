// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit
import os.log

actor ValidationRepositoryImpl: ValidationRepository {
    let projectID: ProjectID
    let urlGenerator: URLGenerator

    private var visionClassifier: SingleAnnotationVisionClassifier?
    private var samplePredictionCache: [UUID: Prediction] = [:]

    init(projectID: ProjectID,
         urlGenerator: URLGenerator) {
        self.projectID = projectID
        self.urlGenerator = urlGenerator
    }

    // MARK: - ValidationRepository

    func loadModel() async throws {
        if visionClassifier != nil {
            os_log(.info, "Model is already loaded, not loading it again.")
            return
        }
        let modelURL = urlGenerator.modelFileURL
        do {
            visionClassifier = try await SingleAnnotationVisionClassifier(modelURL: modelURL)
        } catch let error {
            os_log(.error, "Failed to compile model at URL \(modelURL) \(error)")
            throw ValidationRepositoryError.modelCompileFailed
        }
    }

    func unloadModel() async {
        visionClassifier = nil
        samplePredictionCache.removeAll()

        // Unloading a model needs to trigger a project changed notification,
        // so that evaluation pages may update if they happen to be foregrounded
        // when training completes.
        NotificationCenter.default.post(projectID: projectID)
    }

    func classify(labeledImage: LabeledImage) async throws -> Prediction {
        guard let visionClassifier else {
            throw ValidationRepositoryError.classifierNotLoaded
        }
        let sampleID = labeledImage.sampleID
        if let cachedResult = samplePredictionCache[sampleID] {
            return cachedResult
        }
        let result = try await visionClassifier.classify(sample: labeledImage.image)
        samplePredictionCache[sampleID] = result
        return result
    }
}
