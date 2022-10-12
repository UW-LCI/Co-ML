// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct PrepareDataGridView: View {
    let viewModel: [LabelRibbonViewState]
    let imageNamespace: Namespace.ID
    @FocusState.Binding var focus: LabelID?

    let fetchImage: (UUID) async throws -> UIImage
    let navigate: (GridViewLink) -> ProjectFullScreenRoute
    let action: (GridViewAction) -> Void

    var body: some View {
        RibbonGridView(ribbonViewStates: viewModel,
                       focus: $focus,
                       fetchImage: fetchImage,
                       navigate: navigate,
                       action: action
        ) { _, imageID in
            SampleCardView(imageID: imageID,
                           fetchImage: fetchImage,
                           imageNamespace: imageNamespace
            ) {
                action(.showImage(id: imageID))
            }
            .modifier(DeleteImageContextMenu(action: {
                action(.deleteImage(imageID))
            }))
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    PrepareDataGridPreviewView(state: .fake)
}

struct PrepareDataGridPreviewView: View {
    var state: [LabelRibbonViewState]
    @Namespace private var imageNamespace

    var body: some View {
        PrepareDataGridView(
            viewModel: state,
            imageNamespace: imageNamespace,
            focus: FocusState().projectedValue,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            navigate: {
                print("Navigate to '\($0)'.")
                return .fakeCameraRoute
            },
            action: {
                print("Action: '\($0)'.")
            }
        )
    }
}

#endif
