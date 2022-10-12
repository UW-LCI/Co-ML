// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

@MainActor
final class EvaluationLabelDetailViewModel: ObservableObject {
    @Published private(set) var viewState: EvaluationLabelDetailViewState = .loading

    private let repository: EvaluationLabelDetailRepository
    private let imageFetchRepository: ImageFetchRepository

    init(repository: EvaluationLabelDetailRepository,
         imageFetchRepository: ImageFetchRepository
    ) {
        self.repository = repository
        self.imageFetchRepository = imageFetchRepository
    }

    func monitorProjectChanges() async {
        await updateViewState()

        for await _ in NotificationCenter.default.notifications(projectID: projectID) {
            await updateViewState()
        }
    }

    func fetchImage(_ sampleID: UUID) async throws -> UIImage {
        try await imageFetchRepository.fetchImage(sampleUUID: sampleID)
    }
}

// MARK: - Private

private extension EvaluationLabelDetailViewModel {

    func updateViewState() async {
        viewState = await repository.fetchEvaluationLabelDetailViewState()
    }

    var projectID: ProjectID {
        repository.labelID.projectID
    }
}
