// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationLabelDetailView: View {
    let cameraRoute: ProjectFullScreenRoute
    let gridViewAction: (GridViewAction) -> Void

    @StateObject private var viewModel: EvaluationLabelDetailViewModel

    init(evaluationLabelDetailRepository: EvaluationLabelDetailRepository,
         imageFetchRepository: ImageFetchRepository,
         cameraRoute: ProjectFullScreenRoute,
         gridViewAction: @escaping (GridViewAction) -> Void
    ) {
        self.cameraRoute = cameraRoute
        self.gridViewAction = gridViewAction

        _viewModel = StateObject(wrappedValue: {
            EvaluationLabelDetailViewModel(repository: evaluationLabelDetailRepository,
                                           imageFetchRepository: imageFetchRepository)
        }())
    }

    var body: some View {
        EvaluationLabelDetailInnerView(
            state: viewModel.viewState,
            cameraRoute: cameraRoute,
            fetchImage: viewModel.fetchImage,
            action: gridViewAction)
        .task {
            await viewModel.monitorProjectChanges()
        }
    }
}

private struct EvaluationLabelDetailInnerView: View {
    let state: EvaluationLabelDetailViewState
    let cameraRoute: ProjectFullScreenRoute
    let fetchImage: (UUID) async throws -> UIImage
    let action: (GridViewAction) -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView()

        case let .loaded(label, cardViewStates):
            EvaluationLabelDetailMainView(
                label: label,
                cardViewStates: cardViewStates,
                cameraRoute: cameraRoute,
                fetchImage: fetchImage,
                action: action)

        case let .disappeared(lastKnownLabelTitle, lastKnownImageCount):
            EvaluationLabelDisappearedView(
                lastKnownLabelTitle: lastKnownLabelTitle,
                lastKnownImageCount: lastKnownImageCount
            )
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Loading") {
    EvaluationLabelDetailInnerView.fake(
        state: .loading
    )
}

#Preview("Disappeared") {
    EvaluationLabelDetailInnerView.fake(
        state: .disappeared(
            lastKnownLabelTitle: "Apples",
            lastKnownImageCount: 35
        )
    )
}

#Preview("Populated") {
    EvaluationLabelDetailInnerView.fake(
        state: .loaded(
            label: .fakeAppleLabel,
            cardViewStates: .fakeGradedCardViews
        )
    )
}

extension EvaluationLabelDetailInnerView {
    static func fake(state: EvaluationLabelDetailViewState) -> Self {
        Self(
            state: state,
            cameraRoute: .fakeCameraRoute,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            action: {
                print("Action: '\($0)'.")
            }
        )
    }
}

#endif
