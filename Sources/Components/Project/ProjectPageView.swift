// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct ProjectPageView: View {
    @ObservedObject private(set) var viewModel: ProjectRootViewModel

    @Binding private(set) var title: String

    @State private var showOfflinePopup = false

    var body: some View {
        Group {
            switch viewModel.activePage {
            case .trainingData:
                trainingDataPage
            case .evaluation:
                evaluationPage
            case .export:
                exportPage
            case .training:
                trainingPage
            }
        }
        .navigationTitle($title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.browser)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                customBackButton
            }

            ToolbarItemGroup(placement: .automatic) {
                navigationButton(page: .trainingData)
                navigationButton(page: .training)
                navigationButton(page: .evaluation)
                navigationButton(page: .export)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                cameraButton
                shareButton
            }
        }
    }

    @ViewBuilder
    private func navigationButton(page: ProjectPage) -> some View {
        let isCurrent = viewModel.activePage == page
        Button { [weak viewModel] in
            os_log(.info, "Navigation button tapped \(page)")
            viewModel?.switchPage(to: page)
        } label: {
            Text(page.localizedTitle)
        }
        .padding(3) // match button plumpness of design
        .fixedSize() // creates shorter button to match design
        .background(isCurrent ? Color.accentColor : .clear)
        .foregroundColor(isCurrent ? .white : .primary)
        .clipShape(Capsule(style: .continuous))
        .scaledToFit()
        .padding(.vertical, 10)
        .contentShape(Rectangle())
//        .id(page.localizedTitle + "_toolbarItemID")
    }

    private var trainingDataPage: some View {
        PrepareDataView(viewModel: viewModel.trainingDataViewModel,
                         action: viewModel.resolveGridActions(for: .training))
    }

    private var trainingPage: some View {
        TrainingRootView(
            viewModel: viewModel.trainingViewModel,
            navigateToTestPage: {
                viewModel.switchPage(to: .evaluation)
            }
        )
    }

    private var evaluationPage: some View {
        EvaluationView(viewModel: viewModel.evaluationViewModel,
                       navigateToTrainingPage: {
                           viewModel.switchPage(to: .training)
                       },
                       action: viewModel.resolveGridActions(for: .testing))
    }

    private var exportPage: some View {
        ExportView(viewModel: viewModel.exportViewModel)
    }

    private var shareButton: some View {
        ObservableObjectHostingView(model: viewModel.sharingController) { model in
            ProjectShareButton(shareState: model.shareState, online: model.isOnline) {
                os_log(.info, "Share Button Pressed!")
                Task {
                    if model.isOnline {
                        model.presentCloudSharingController()
                    } else {
                        showOfflinePopup = true
                    }
                }
            }
        }
        .onAppear {
            viewModel.sharingController.monitorNetworkConnection()
        }
        .onDisappear {
            viewModel.sharingController.stopMonitoringNetworkConnection()
        }
        .alert(
            .youreOffline,
            isPresented: $showOfflinePopup,
            actions: {
                Button(.ok) {
                    // No-op. Any alert action automatically falsifies the `$isPresented` binding.
                }
            },
            message: {
                Text(.pleaseConnectToTheInternetToShareThisProject)
            })
    }

    private var customBackButton: some View {
        Button { [weak viewModel] in
            os_log(.info, "Back button pressed: Return to project gallery")
            viewModel?.exitProject()
        } label: {
            Label(.back, systemImage: "chevron.backward")
                .padding()
                .contentShape(Rectangle())
        }

        .fontWeight(.semibold)
    }

    @ViewBuilder
    private var cameraButton: some View {
        // camera is on collect mode by default, on train bucket by default
        let saveDestination = viewModel.activePage == .evaluation ? DataType.testing : DataType.training
        NavigationLink(value: ProjectFullScreenRoute.cameraPage(
            projectID: viewModel.projectID,
            settings: CameraSettings(saveDestination: saveDestination, viewMode: .collectionMode)
        )) {
            Label(.openCamera, systemImage: "camera.fill")
        }
    }
}
