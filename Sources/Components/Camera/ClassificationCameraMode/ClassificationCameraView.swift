// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI
import os.log

/// A view that shows a camera preview and allows the user to snap a photo and see a classification result
struct ClassificationCameraView: View {

    @ObservedObject private(set) var viewModel: ClassificationCameraViewModel

    var body: some View {
        CameraUIContent(
            leftMarginContents: EmptyView(),
            cameraOverlayContents: CameraPredictionOverlay(
                viewModel: viewModel
            ),
            aboveShutterControls: EmptyView(),
            belowShutterControls: EmptyView(),
            showBackgroundMaterial: false
        )
        .sheet(isPresented: $viewModel.showResultSheet) {
            if let state = viewModel.predictionSummaryViewState {
                PredictionSummaryView(state: state, dismiss: viewModel.dismiss, savePhoto: viewModel.savePhoto)
            }
        }
        .task {
            // This sets up live & photo-based classification.
            await viewModel.processClassification()
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    ClassificationCameraView(viewModel: .fake)
}

#endif
