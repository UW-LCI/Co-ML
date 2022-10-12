// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import SwiftUI

struct PrepareDataView: View {

    @ObservedObject private(set) var viewModel: PrepareDataViewModel
    let action: (GridViewAction) -> Void

    @Namespace private var imageNamespace

    var body: some View {
        PrepareDataInnerView(projectID: viewModel.projectID,
                             fetchImage: viewModel.fetchImage,
                             viewMode: viewModel.viewMode,
                             labelStats: viewModel.labelStats,
                             albumCoverViewStates: viewModel.albumCoverViewStates,
                             createNewLabel: viewModel.createNewLabel,
                             action: action)
        .task {
            await viewModel.monitorProjectChanges()
        }
    }
}

struct PrepareDataInnerView: View {
    let projectID: ProjectID
    let fetchImage: (UUID) async throws -> UIImage
    let viewMode: PrepareDataViewModel.ViewMode
    let labelStats: [PrepareDataStatsRow]
    let albumCoverViewStates: [LabelRibbonViewState]
    let createNewLabel: () -> LabelID
    let action: (GridViewAction) -> Void
    @FocusState private var focusLabel: LabelID?

    @Namespace private var imageNamespace

    var body: some View {
        Group {
            switch viewMode {
            case .loading:
                loadingView
            case .grid:
                gridView
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView {
                VStack {
                    Text(.loadingTrainingData)
                }
            }
            Spacer()
        }
    }

    /// When the Training Image Grid requests navigation, resolve it here
    func navigation(to link: GridViewLink) -> ProjectFullScreenRoute {
        switch link {
        case .openCamera(for: let label):
            return .cameraPage(projectID: projectID, settings: CameraSettings(annotation: label, saveDestination: .training, viewMode: .collectionMode))
        case .openLabel(for: let label):
            return .labelDetailPage(projectID: projectID, labelAnnotation: label, dataType: .training, imageNamespace: imageNamespace)
        }
    }

    private var gridView: some View {
        HStack(spacing: 0) {
            PrepareDataSidebar(labelStats: labelStats)
                .background(Color(UIColor.systemGray6))

            PrepareDataGridView(viewModel: albumCoverViewStates,
                                imageNamespace: imageNamespace,
                                focus: $focusLabel,
                                fetchImage: fetchImage,
                                navigate: navigation(to:),
                                action: action)
            // Safe area creates the bottom bar and correctly stops scroll content at the edge
            .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
                plusButtonBar
                    .background(.bar)
            }
        }
        .onTapGesture(perform: hideKeyboard)

    }

    private var plusButtonBar: some View {
        HStack {
            Button {
                os_log(.info, "Plus button tapped to add a new label")
                let id = createNewLabel()
                focusLabel = id
            } label: {
                Label {
                    Text(.addLabel)
                } icon: {
                    Image(systemName: "plus.square.fill")
                        .imageScale(.large)

                }
                .symbolRenderingMode(.hierarchical)
                .padding()
                .contentShape(Rectangle())
            }
            Spacer()
        }
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NavigationStack {
        VStack {
            PrepareDataInnerView(
                projectID: .fakeProjectID,
                fetchImage: ImageFetchRepositoryFake.fetchImage,
                viewMode: .grid,
                labelStats: .fakeFruits,
                albumCoverViewStates: .fake,
                createNewLabel: {
                    print("Create new label")
                    return LabelID(id: UUID(), projectID: .fakeProjectID)
                }, action: { gridViewAction in
                    print("Grid view action \(gridViewAction)")
                }
            )
        }
        .toolbar {
            Button {
                // No-op
            } label: {
                Text(verbatim: "Hey")
            }
        }
        .navigationTitle("Sample")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
