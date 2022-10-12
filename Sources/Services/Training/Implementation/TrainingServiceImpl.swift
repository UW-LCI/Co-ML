// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log
import SwiftUI
import Combine

#if canImport(CreateML)
import CreateML
#else
#warning("CreateML is required for real training, but Simulator is not supported.")
#endif

actor TrainingServiceImpl: TrainingService {

    private let project: Project
    private let urlGenerator: URLGenerator
    private let analyticsService: TrainingAnalyticsService
    private let databaseStorageService: DatabaseStorageService
    private var datasetsRepository: DatasetsRepository
    private var validationRepository: ValidationRepository
    private var projectModelInfo: ProjectModelInfo?

    private var trainingTask: Task<Void, Never>?

    init(project: Project,
         urlGenerator: URLGenerator,
         datasetsRepository: DatasetsRepository,
         validationRepository: ValidationRepository,
         analyticsService: TrainingAnalyticsService,
         databaseStorageService: DatabaseStorageService
    ) {
        self.project = project
        self.urlGenerator = urlGenerator
        self.datasetsRepository = datasetsRepository
        self.analyticsService = analyticsService
        self.validationRepository = validationRepository
        self.databaseStorageService = databaseStorageService
    }

    deinit {
        trainingTask?.cancel()
    }

    // MARK: - TrainingService

    func train(_ projectModelInfo: ProjectModelInfo) async throws -> AsyncStream<TrainingState> {
        if let trainingTask {
            os_log(.debug, "Cancelling the prior training task.")
            trainingTask.cancel()
            self.trainingTask = nil
        }

        return AsyncStream { continuation in
            trainingTask = .init(priority: .userInitiated) {
                analyticsService.logTrainingStarted(
                    labelCount: projectModelInfo.labels.count,
                    sampleCount: projectModelInfo.sampleCount)

                do {
                    continuation.yield(.preparingDataset)

                    try await prepareSelectedDatasetToDisk()
                    continuation.yield(.datasetPrepared)

                    // Since these are both potentially long-running tasks, check cancellation between them.
                    try Task.checkCancellation()

                    try await performTrainingWithDatasetOnDisk()
                    projectModelInfo.write(to: urlGenerator.projectModelInfoURL)
                    continuation.yield(.finishedTraining)

                    analyticsService.logTrainingFinished()

                } catch {
                    analyticsService.logTrainingFailed()
                    continuation.yield(.failed)
                }

                // Make sure the model is unloaded so prior evaluations are cleaned up.
                await validationRepository.unloadModel()

                continuation.finish()
                cleanUpTrainingTask()
            }
        }
    }

    // MARK: - Private

    private var projectID: ProjectID {
        project.id
    }

    private var trainingDataURL: URL {
        urlGenerator.projectDataDirectoryURL
    }

    private func prepareSelectedDatasetToDisk() async throws {
        let preparedDataset = try await datasetsRepository.prepareDataset()
        try TrainingDataWriter.write(dataset: preparedDataset,
                                     to: trainingDataURL,
                                     databaseStorageService: databaseStorageService)
    }

    private func cleanUpTrainingTask() {
        self.trainingTask = nil
    }
}

#if canImport(CreateML)

extension TrainingServiceImpl {
    private func performTrainingWithDatasetOnDisk() async throws {
        let trainingData = MLImageClassifier.DataSource.labeledDirectories(at: trainingDataURL)
        let classifier = try MLImageClassifier(trainingData: trainingData)
        let modelFileURL = urlGenerator.modelFileURL
        try classifier.write(to: modelFileURL, metadata: modelMetadata)
    }

    private var modelMetadata: MLModelMetadata {
        .init(author: "Co-ML",
              shortDescription: "Model from \(project.title)",
              version: "1.0")
    }
}

#else

extension TrainingServiceImpl {
    private func performTrainingWithDatasetOnDisk() async throws {
        throw TrainingServiceError.serviceNotAvailable
    }
}

#endif
