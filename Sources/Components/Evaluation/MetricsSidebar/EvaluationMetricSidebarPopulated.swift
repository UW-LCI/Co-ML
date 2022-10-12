// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct EvaluationMetricSidebarPopulated: View {
    let metrics: EvaluationMetrics

    var body: some View {
        VStack(alignment: .center) {
            testResultsHeading
            metricsSummaryTable
            Spacer()
            previewModelButton
        }
    }

    private var testResultsHeading: some View {
        VStack(alignment: .leading) {
            Text(.testModel)
                .font(.title2)
                .fontWeight(.medium)
            accuracyBig
        }
        .padding(.sidebar.padding)
    }

    private var metricsSummaryTable: some View {
        MetricsSummaryList(metrics: metrics.metricTableRows)
    }

    private var accuracyBig: some View {
        VStack(alignment: .leading) {
            Text(metrics.percentCorrectForAllLabels)
                .font(.system(size: 64, weight: .regular, design: .rounded))
                .padding(.top, 0.5)

            Text(.correct)
                .fontWeight(.semibold)

            Text(.theModelWasAbleToCorrectlyClassifyOfYourTestImages(metrics.correctSampleCount))
                .fontWeight(.regular)
                .foregroundColor(Color(uiColor: .label))
                .multilineTextAlignment(.leading)
                .padding(.top)
        }
    }

    private var previewModelButton: some View {
        NavigationLink(value: ProjectFullScreenRoute.cameraPage(
            projectID: metrics.projectID,
            settings: CameraSettings(
                saveDestination: .testing, viewMode: .classificationMode
            ))) {
                Label(.previewModel, systemImage: "camera.fill")
                    .fontWeight(.semibold)
                    .padding(4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.sidebar.padding)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    EvaluationMetricSidebarPopulated(
        metrics: .fake
    )
}

#endif
