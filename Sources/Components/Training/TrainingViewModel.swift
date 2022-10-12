// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Combine
import os.log

@MainActor
class TrainingViewModel: ObservableObject {

    @Published var trainingViewState: TrainingViewState
    private let project: Project
    private let projectModelInfoRepository: ProjectModelInfoRepository
    private let trainingService: TrainingService
    private let modelStorageService: ModelStorageService

    init(project: Project,
         projectModelInfoRepository: ProjectModelInfoRepository,
         trainingService: TrainingService,
         modelStorageService: ModelStorageService
    ) {
        self.project = project
        self.projectModelInfoRepository = projectModelInfoRepository
        self.trainingService = trainingService
        self.modelStorageService = modelStorageService

        self.trainingViewState = TrainingViewState(projectID: project.id,
                                                   projectName: project.title)
    }

    var projectID: ProjectID {
        project.id
    }

    /// User requests training to start (sync version)
    ///
    /// This triggers the trainingService to execute training, which will
    /// go through multiple states monitored in monitorTrainingState
    /// before finishing with a model.
    ///
    /// assumes data is ready to train
    func startTraining() {
        Task(priority: .userInitiated) {
            do {
                try await train()
            } catch {
                trainingViewState.errorDuringTraining = error.localizedDescription
            }
        }
    }

    /// Listen for project updates, which may result in updates to training readiness.
    func monitorProjectChanges() async {

        // Start with an initial refresh.
        await refreshTrainingData()

        os_log(.debug, "Monitor project changes…")

        // Then handle project changes going forward.
        for await _ in NotificationCenter.default.notifications(projectID: projectID) {
            await refreshTrainingData()
        }

        os_log(.debug, "Monitor project changes complete.")
    }
}

// MARK: - Private

private extension TrainingViewModel {

    /// Fetches both the latest (on-disk) model info and project model info, then deriving the appropriate training page.
    func refreshTrainingData() async {
        if trainingViewState.isTraining {
            os_log(.info, "Skipping training data refresh while training.")
            return
        }

        let t0 = CFAbsoluteTimeGetCurrent()
        os_log(.debug, "Refresh training data…")

        do {
            let existingModelInfo = await modelStorageService.fetchModelInfo()
            let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()

            trainingViewState.projectPanelState = projectPanelState(from: projectModelInfo, with: existingModelInfo)
            trainingViewState.modelPanelState = TrainingModelPanel.State(from: existingModelInfo, projectID: projectID)

            let dt = CFAbsoluteTimeGetCurrent() - t0
            os_log(.debug, "Refresh training data done after \(dt) seconds.")

        } catch {
            os_log(.error, "Error in refresh training data: \(error)")
        }
    }

    func projectPanelState(from projectModelInfo: ProjectModelInfo, with existingModelInfo: ModelInfo?) -> TrainingProjectPanel.State {

        // If more data is needed, show the more data needed view regardless of existing model existence.
        guard trainingService.hasEnoughDataToTrain(projectModelInfo) else {
            return .moreDataNeeded
        }

        // If there is enough data, and there is no existing model, we show the ready to train view.
        guard let existingModelProjectInfo = existingModelInfo?.projectModelInfo else {
            let trainableLabelCount = trainingService.trainableLabelCount(projectModelInfo)
            return .readyToTrain(trainableLabelCount: trainableLabelCount, progressState: nil)
        }

        // If there are no changes, show the no updates view.
        let changes = projectModelInfo.changes(since: existingModelProjectInfo)
        if changes.isEmpty {
            return .noUpdatesAvailable
        }

        return .updatesAvailable(progressState: nil, changes: changes)
    }

    /// Performs training with the latest project model info.
    func train() async throws {

        // The training service requires project model info to train.
        let projectModelInfo = try await projectModelInfoRepository.fetchProjectModelInfo()

        // Now we "monitor" in the same place we "train."
        os_log(.debug, "Monitor training state…")

        trainingViewState.modelPanelState = .training
        trainingViewState.isTraining = true

        let trainingStream = try await trainingService.train(projectModelInfo)

        for try await trainingState in trainingStream {
            let progressState = TrainingModelView.ProgressState(from: trainingState)
            trainingViewState.projectPanelState.updateProgress(with: progressState)
        }

        trainingViewState.isTraining = false

        await refreshTrainingData()

        os_log(.debug, "Monitor training state complete.")
    }
}

private extension TrainingProjectPanel.State {
    mutating func updateProgress(with progressState: TrainingModelView.ProgressState) {
        switch self {
        case .loading, .moreDataNeeded, .noUpdatesAvailable:
            assertionFailure("Project panel state \(self) can't be updated with progress.")
            return

        case .readyToTrain(let trainableLabelCount, _):
            self = .readyToTrain(trainableLabelCount: trainableLabelCount, progressState: progressState)

        case .updatesAvailable(_, let changes):
            self = .updatesAvailable(progressState: progressState, changes: changes)
        }
    }
}

private extension TrainingModelView.ProgressState {
    init(from trainingState: TrainingState) {
        switch trainingState {
        case .notStarted:
            self = .init(progress: 0.0, subtitle: "")

        case .preparingDataset:
            self = .init(progress: 0.3, subtitle: String(localized: .copyingFiles))

        case .datasetPrepared:
            self = .init(progress: 0.6, subtitle: String(localized: .learningFromYourData))

        case .finishedTraining, .failed:
            self = .init(progress: 1.0, subtitle: "")
        }
    }
}

private extension TrainingModelPanel.State {
    init(from modelInfo: ModelInfo?, projectID: ProjectID) {
        if let modelInfo {
            self = .previewAvailable(projectID: projectID, lastTrained: modelInfo.creationDate)
        } else {
            self = .noModelAvailable
        }
    }
}

#if DEBUG

extension TrainingViewModel {
    static var fake = TrainingViewModel(
        project: .fake,
        projectModelInfoRepository: .fake,
        trainingService: .fake,
        modelStorageService: .fake()
    )
}

#endif
