// Copyright 2026 Apple Inc. All rights reserved.

import Combine
import Foundation
import os.log
import UIKit
import SwiftUI

/// Wraps a sidebar view model and evaluation grid view model.
///
/// Also provides a singular hook to the evaluation repository allowing `evaluate()` to be called, whose output is
/// subsequently observed by both child view models.
@MainActor
final class EvaluationViewModel: ObservableObject {

    @Published private(set) var evaluationViewState: EvaluationViewState = .loading

    private let evaluationRepository: EvaluationRepository
    private let imageFetchRepository: ImageFetchRepository

    init(evaluationRepository: EvaluationRepository, imageFetchRepository: ImageFetchRepository) {
        self.evaluationRepository = evaluationRepository
        self.imageFetchRepository = imageFetchRepository
    }

    var projectID: ProjectID {
        evaluationRepository.projectID
    }

    /// Like all other similar view models, this guy will monitor ALL project changes.
    func monitorProjectChanges() async {

        // Start with an initial evaluation pass.
        await evaluate()

        os_log(.info, "Start monitoring project changes…")

        for await _ in NotificationCenter.default.notifications(projectID: projectID) {

            os_log(.info, "Kicking off evaluation for project \(self.projectID)…")
            await evaluate()
        }

        os_log(.info, "End monitoring project changes.")
    }

    func fetchImage(_ sampleID: UUID) async throws -> UIImage {
        try await imageFetchRepository.fetchImage(sampleUUID: sampleID)
    }
}

// MARK: - Private

private extension EvaluationViewModel {

    /// Here is where the magic happens. We'll need things from lower level entities here.
    func evaluate() async {
        let evaluationRepositoryState = await evaluationRepository.evaluate()

        let sidebarViewState = EvaluationMetricSidebarViewState(projectID: projectID,
                                                                evaluationRepositoryState: evaluationRepositoryState)

        let gridViewState = EvaluationGridViewState(projectID: projectID,
                                                    evaluationRepositoryState: evaluationRepositoryState)

        withAnimation {
            evaluationViewState = .loaded(sidebarViewState: sidebarViewState,
                                          gridViewState: gridViewState)
        }
    }
}

private extension EvaluationMetricSidebarViewState {
    init(projectID: ProjectID, evaluationRepositoryState: EvaluationRepositoryState) {
        switch evaluationRepositoryState {

        case .evaluationCompleted(let evaluationInfo):
            self = .loaded(metrics: EvaluationMetrics(projectID: projectID, evaluationRepositoryInfo: evaluationInfo))

        case .failed(let error):
            self = .failed(error: error)

        case .noModel(let evaluationInfo):
            self = .noModel(labels: evaluationInfo.labelsWithSampleCount)
        }
    }
}

private extension EvaluationGridViewState {
    init(projectID: ProjectID, evaluationRepositoryState: EvaluationRepositoryState) {
        switch evaluationRepositoryState {
        case .noModel(let info):
            self = EvaluationGridViewState(projectID: projectID, evaluationRepositoryInfo: info)
        case .evaluationCompleted(let info):
            self = EvaluationGridViewState(projectID: projectID, evaluationRepositoryInfo: info)
        case .failed(_):
            self = EvaluationGridViewState(projectID: projectID,
                                           isModelOutOfDate: false,
                                           evaluationRibbonViewStates: [])
        }
    }

    init(projectID: ProjectID, evaluationRepositoryInfo: EvaluationRepositoryInfo) {
        let ribbonViewStates = evaluationRepositoryInfo.ribbonViewStates
        self = EvaluationGridViewState(projectID: projectID,
                                       isModelOutOfDate: evaluationRepositoryInfo.isModelOutOfDate,
                                       evaluationRibbonViewStates: ribbonViewStates)
    }
}

private extension EvaluationRepositoryInfo {

    var ribbonViewStates: [EvaluationRibbonViewState] {
        var result: [EvaluationRibbonViewState] = []
        for label in sortedLabels {
            let labelImages = imagesByLabelID[label.id] ?? []
            result.append(EvaluationRibbonViewState(label: label,
                                                    images: labelImages))
        }
        return result
    }
}

#if DEBUG

extension EvaluationViewModel {
    static var fake = EvaluationViewModel(
        evaluationRepository: .fake,
        imageFetchRepository: ImageFetchRepositoryFake()
    )
}

#endif
