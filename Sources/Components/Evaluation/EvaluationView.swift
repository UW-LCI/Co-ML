// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import SwiftUI

struct EvaluationView: View {

    @ObservedObject var viewModel: EvaluationViewModel

    @Namespace private var imageNamespace

    let navigateToTrainingPage: () -> Void
    let action: (GridViewAction) -> Void

    var body: some View {
        Group {
            switch viewModel.evaluationViewState {
            case .loading:
                ProgressView()

            case let .loaded(sidebarViewState, gridViewState):
                HStack(spacing: 0) {

                    EvaluationMetricSidebar(viewState: sidebarViewState)

                    EvaluationResultsView(
                        projectID: viewModel.projectID,
                        viewState: gridViewState,
                        fetchImage: viewModel.fetchImage,
                        navigateToTrainingPage: navigateToTrainingPage,
                        action: action)
                }
            }
        }
        .task {
            await viewModel.monitorProjectChanges()
        }
        .onTapGesture(perform: hideKeyboard)
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Dynamic view") {
    EvaluationView(
        viewModel: .fake,
        navigateToTrainingPage: {
            print("Navigate to training page")
        },
        action: {
            print("Image selected: '\($0)'")
        }
    )
}

#endif
