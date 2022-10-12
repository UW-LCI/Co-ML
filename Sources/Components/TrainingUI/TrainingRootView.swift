// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct TrainingRootView: View {
    @ObservedObject private(set) var viewModel: TrainingViewModel
    var navigateToTestPage: () -> Void

    var body: some View {
        TrainingInnerRootView(
            state: viewModel.trainingViewState,
            navigateToTestPage: navigateToTestPage
        ) {
            viewModel.startTraining()
        }
        .task {
            await viewModel.monitorProjectChanges()
        }
    }
}

struct TrainingBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .trainingCardOverlay()
    }
}

extension GroupBoxStyle where Self == TrainingBoxStyle {
    static var trainingBox: TrainingBoxStyle {
        TrainingBoxStyle()
    }
}

private struct TrainingInnerRootView: View {
    let state: TrainingViewState
    let navigateToTestPage: () -> Void
    let startTraining: () -> Void

    @State private var showTrainingError = false
    @State private var trainingErrorMessage = ""

    var body: some View {
        if #available(iOS 17.0, *) {
            mainContent
                .onChange(of: state.errorDuringTraining) { oldValue, newValue in
                    guard let newValue else {
                        return
                    }
                    if newValue == oldValue {
                        return
                    }

                    trainingErrorMessage = newValue
                    showTrainingError = true
                }
                .alert(
                    .trainingError,
                    isPresented: $showTrainingError,
                    actions: {
                        // No actions.
                    },
                    message: {
                        Text(trainingErrorMessage)
                    }
                )
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground)

            HStack {
                Spacer()
                GroupBox {
                    TrainingProjectPanel(state: state.projectPanelState) {
                        startTraining()
                    }
                }
                Spacer()
                GroupBox {
                    TrainingModelPanel(state: state.modelPanelState) {
                        navigateToTestPage()
                    }
                }
                Spacer()
            }.groupBoxStyle(.trainingBox)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Both panels loading", traits: .landscapeLeft) {
    NavigationStack {
        TrainingInnerRootView.fake(
            state: .fake(
                projectPanelState: .loading,
                modelPanelState: .loading
            )
        )
    }
}

#Preview("Ready, no model", traits: .landscapeLeft) {
    NavigationStack {
        TrainingInnerRootView.fake(
            state: .fake(
                projectPanelState: .readyToTrain(trainableLabelCount: 4, progressState: nil),
                modelPanelState: .noModelAvailable
            )
        )
    }
}

#Preview("Not ready", traits: .landscapeLeft) {
    NavigationStack {
        TrainingInnerRootView.fake(
            state: .fake(
                projectPanelState: .moreDataNeeded,
                modelPanelState: .noModelAvailable
            )
        )
    }
}

#Preview("Model, no updates", traits: .landscapeLeft) {
    NavigationStack {
        TrainingInnerRootView.fake(
            state: .fake(
                projectPanelState: .noUpdatesAvailable,
                modelPanelState: .previewAvailable(projectID: ProjectID(), lastTrained: Date())
            )
        )
    }
}

#Preview("Model, can retrain", traits: .landscapeLeft) {
    NavigationStack {
        TrainingInnerRootView.fake(
            state: .fake(
                projectPanelState: .updatesAvailable(progressState: nil, changes: [.labelAdded(labelString: "Apples")]),
                modelPanelState: .previewAvailable(projectID: ProjectID(), lastTrained: Date())
            )
        )
    }
}

#Preview("In progress (ready)", traits: .landscapeLeft) {
    TrainingInnerRootView.fake(
        state: .fake(
            projectPanelState: .readyToTrain(trainableLabelCount: 4, progressState: .init(progress: 0.3, subtitle: "Copying Files…")),
            modelPanelState: .training
        )
    )
}

#Preview("In progress (updates available)", traits: .landscapeLeft) {
    TrainingInnerRootView.fake(
        state: .fake(
            projectPanelState: .updatesAvailable(progressState: .init(progress: 0.6, subtitle: "Learning from your data…"), changes: []),
            modelPanelState: .training
        )
    )
}

extension TrainingInnerRootView {
    static func fake(state: TrainingViewState) -> Self {
        .init(
            state: state,
            navigateToTestPage: {
                print("Action: Navigate to test page.")
            },
            startTraining: {
                print("Action: Start training.")
            }
        )
    }
}

#endif
