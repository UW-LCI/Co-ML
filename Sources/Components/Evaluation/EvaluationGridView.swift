// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct EvaluationResultsView: View {
    let projectID: ProjectID
    let viewState: EvaluationGridViewState

    @Namespace private var imageNamespace

    let fetchImage: (UUID) async throws -> UIImage
    let navigateToTrainingPage: () -> Void
    let action: (GridViewAction) -> Void

    var body: some View {
        mainView
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var mainView: some View {
        EvaluationGridView(viewState: viewState,
                           imageNamespace: imageNamespace,
                           fetchImage: fetchImage,
                           navigate: navigation(to:),
                           navigateToTrainingPage: navigateToTrainingPage,
                           action: action)
    }

    /// When the Evaluation Image Grid requests navigation, resolve it here
    func navigation(to link: GridViewLink) -> ProjectFullScreenRoute {
        switch link {
        case .openCamera(for: let label):
            return .cameraPage(
                projectID: projectID,
                settings: CameraSettings(
                    annotation: label, saveDestination: .testing,
                    viewMode: .collectionMode))

        case .openLabel(for: let label):
            return .labelDetailPage(
                projectID: projectID,
                labelAnnotation: label,
                dataType: .testing,
                imageNamespace: imageNamespace)
        }
    }
}

private struct EvaluationGridView: View {

    let viewState: EvaluationGridViewState
    let imageNamespace: Namespace.ID

    let fetchImage: (UUID) async throws -> UIImage
    let navigate: (GridViewLink) -> ProjectFullScreenRoute
    let navigateToTrainingPage: () -> Void
    let action: (GridViewAction) -> Void

    @FocusState private var focusedLabel: LabelID?

    var body: some View {
        VStack {
            if viewState.isModelOutOfDate {
                ModelOutOfDateBar(alignment: .leading) {
                    navigateToTrainingPage()
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .background(in: RoundedRectangle(cornerRadius: 10))
                .padding()
                .transition(.move(edge: .top))
            }
            RibbonGridView(ribbonViewStates: viewState.labelRibbonViewStates,
                           focus: $focusedLabel,
                           fetchImage: fetchImage,
                           navigate: navigate,
                           action: action
            ) { label, imageID in
                GradedCardView(
                    state: GradedCardViewState(prediction: viewState.prediction(labeledImageID: imageID),
                                               imageID: imageID),
                    imageNamespace: imageNamespace,
                    fetchImage: fetchImage
                ) {
                    action(.showImage(id: imageID))
                } delete: { imageID in
                    action(.deleteImage(imageID))
                }
                .frame(width: .tile.width)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    EvaluationResultsView(
        projectID: .fakeProjectID,
        viewState: .fake,
        fetchImage: ImageFetchRepositoryFake.fetchImage,
        navigateToTrainingPage: {
            print("Navigate to training page")
        },
        action: {
            print("Grid view action: '\($0)'.")
        }
    )
}

#endif
