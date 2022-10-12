// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationMetricModelWithoutDataSidebar: View {
    let projectID: ProjectID

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                testResultsHeading
                testingHelpTextView
            }

            Spacer()
            previewModelButton
        }
        .padding(.sidebar.padding)
    }

    private var testResultsHeading: some View {
        Text(.testModel)
            .font(.title2)
            .fontWeight(.medium)
    }

    private var testingHelpTextView: some View {
        VStack {
            Text(.addTestImagesToSeeHowWellYourModelWorks)
            .foregroundColor(.secondary)
            .padding()
        }
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(10)
    }

    private var previewModelButton: some View {
        NavigationLink(value: ProjectFullScreenRoute.cameraPage(
            projectID: projectID,
            settings: CameraSettings(
                saveDestination: .testing, viewMode: .classificationMode
            ))) {
                Text(.previewModel)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.sidebar.padding)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("No test data") {
    EvaluationMetricModelWithoutDataSidebar(
        projectID: .fakeProjectID
    )
}

#endif
