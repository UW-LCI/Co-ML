// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationLabelDetailMainView: View {
    let label: LabelAnnotation
    let cardViewStates: [GradedCardViewState]
    let cameraRoute: ProjectFullScreenRoute
    let fetchImage: (UUID) async throws -> UIImage
    let action: (GridViewAction) -> Void

    @Namespace private var imageNamespace
    @FocusState private var isLabelTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            SubmitTextField(
                label: label.labelString,
                isFocused: isLabelTitleFocused,
                submit: {
                    action(.rename(label, to: $0))
                }
            )
            .font(.title2.bold())

            VStack(alignment: .leading) {
                Text(.imageCountSubtitle(cardViewStates.count))
            }
            .font(.subheadline)
            .foregroundColor(Color(uiColor: .secondaryLabel))

            EvaluationLabelDetailGridView(
                cardViewStates: cardViewStates,
                imageNamespace: imageNamespace,
                fetchImage: fetchImage,
                action: action)
        }
        .padding()
        .toolbar {
            toolbarItems
        }
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: .tile.spacing), count: 7)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(.testImages)
            .font(.headline)
        }
        ToolbarItem {
            NavigationLink(value: cameraRoute) {
                Label(.openCamera, systemImage: "camera.fill")
            }
        }
        ToolbarItem {
            Button {
                action(.photosAppImport(to: label))
            } label: {
                Label(.openPhotoAlbum, systemImage: "photo")
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NavigationStack {
        EvaluationLabelDetailMainView(
            label: .fakeAppleLabel,
            cardViewStates: .fakeGradedCardViews,
            cameraRoute: .cameraPage(
                projectID: .fakeProjectID,
                settings: .init(
                    annotation: .fakeAppleLabel,
                    saveDestination: .testing,
                    viewMode: .collectionMode
                )
            ),
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            action: { action in
                print("Action: '\(action)'.")
            }
        )
    }
}

#endif
