// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationMetricSidebar: View {
    let viewState: EvaluationMetricSidebarViewState

    var body: some View {
        HStack {
            innerView
            Divider()
        }
        .background(Color(UIColor.systemGray6))
        .frame(width: .sidebar.width)
        .fixedSize(horizontal: true, vertical: false)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var innerView: some View {
        switch viewState {
        case let .loaded(metrics):
            EvaluationMetricSidebarPopulated(metrics: metrics)

        case let .noModel(labels):
            EvaluationMetricNoModelSidebar(labels: labels)

        case let .modelWithoutData(projectID):
            EvaluationMetricModelWithoutDataSidebar(projectID: projectID)

        case .failed:
            Label {
                Text(.evaluationFailed)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Failed") {
    EvaluationMetricSidebar(
        viewState: .failed(
            error: DatabaseStorageServiceError.notAvailable
        )
    )
}

#Preview("Test results unavailable") {
    EvaluationMetricSidebar(
        viewState: .noModel(
            labels: .fakeLabelsWithSampleCount
        )
    )
}

#Preview("No model, no labels") {
    EvaluationMetricSidebar(
        viewState: .noModel(
            labels: []
        )
    )
}

#Preview("Metrics") {
    EvaluationMetricSidebar(
        viewState: .loaded(
            metrics: EvaluationMetrics(
                projectID: .fakeProjectID,
                sampleCount: 500,
                correctSampleCount: 400,
                percentCorrectForAllLabels: "80%",
                metricTableRows: [
                    MetricTableRow(
                        label: "A really long name",
                        percentCorrect: "70%",
                        count: 100
                    ),
                    MetricTableRow(
                        label: "Banana",
                        percentCorrect: "80%",
                        count: 200
                    ),
                    MetricTableRow(
                        label: "Carrot",
                        percentCorrect: "90%",
                        count: 200
                    ),
                ]
            )
        )
    )
}

#Preview("No Test Data") {
    EvaluationMetricSidebar(
        viewState: .modelWithoutData(
            projectID: .fakeProjectID
        )
    )
}

#endif
