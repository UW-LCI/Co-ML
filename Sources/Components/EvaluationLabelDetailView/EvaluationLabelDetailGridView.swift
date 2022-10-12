// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// A view that shows a grid of evaluated images, all corresponding to a particular label.
struct EvaluationLabelDetailGridView: View {
    let cardViewStates: [GradedCardViewState]
    let imageNamespace: Namespace.ID
    let fetchImage: (UUID) async throws -> UIImage
    let action: (GridViewAction) -> Void

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: gridItems, spacing: .tile.spacing) {
                ForEach(cardViewStates) { state in
                    GradedCardView(
                        state: state,
                        imageNamespace: imageNamespace,
                        fetchImage: fetchImage,
                        action: {
                            action(.showImage(id: state.imageID))
                        },
                        delete: { imageID in
                            action(.deleteImage(imageID))
                        }
                    )
                    .padding(.bottom)
                }
            }
        }
    }

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: .tile.spacing), count: 7)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    EvaluationLabelDetailGridPreviewView(
        cardViewStates: .fakeGradedCardViews
    )
}

struct EvaluationLabelDetailGridPreviewView: View {
    var cardViewStates: [GradedCardViewState]
    @Namespace private var imageNamespace

    var body: some View {
        EvaluationLabelDetailGridView(
            cardViewStates: cardViewStates,
            imageNamespace: imageNamespace,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            action: { action in
                print("Action: \(action)")
            }
        )
        .padding()
    }
}

#endif
