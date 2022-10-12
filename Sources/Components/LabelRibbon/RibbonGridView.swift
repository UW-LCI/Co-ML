// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

// a grid of ribbons shows a ribbon for each label
struct RibbonGridView<CardView: View>: View {

    let ribbonViewStates: [LabelRibbonViewState]
    /// Reading focus allow us to scroll the ribbon grid to bring the label we are editing onscreen.
    @FocusState.Binding var focus: LabelID?

    let fetchImage: (UUID) async throws -> UIImage
    let navigate: (GridViewLink) -> ProjectFullScreenRoute
    let action: (GridViewAction) -> Void

    /// How to draw the card view for each labelled image
    let cardView: (LabelAnnotation, LabeledImageID) -> CardView

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.vertical) {
                drawRibbonView
            }
            .onChange(of: focus) { id in
                if let id {
                    withAnimation {
                        reader.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private var drawRibbonView: some View {
        ForEach(ribbonViewStates, id: \.label.id) { ribbonState in
            let openLabel = navigate(.openLabel(ribbonState.label))
            let openCamera = navigate(.openCamera(for: ribbonState.label))
            RibbonView(
                viewModel: ribbonState,
                fetchImage: fetchImage,
                action: action,
                openLabel: openLabel,
                openCamera: openCamera
            ) { imageID in
                cardView(ribbonState.label, imageID)
            }
            .focused($focus, equals: ribbonState.label.id)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NavigationStack {
        RibbonGridView(
            ribbonViewStates: .fake,
            focus: FocusState().projectedValue,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            navigate: {
                print("Navigate to \($0).")
                return .fakeCameraRoute
            },
            action: {
                print("Action '\($0)'.")
            },
            cardView: { label, imageID in
                SampleImageView {
                    try await ImageFetchRepositoryFake.fetchImage(imageID.sampleID)
                }
                .frame(width: 40, height: 40)
            }
        )
        .padding()
        .navigationDestination(for: ProjectFullScreenRoute.self) { route in
            Text(verbatim: "Routed to \(String(describing: route))")
        }
        .toolbar {

        }.navigationBarBackButtonHidden(false)

    }
}

#endif
