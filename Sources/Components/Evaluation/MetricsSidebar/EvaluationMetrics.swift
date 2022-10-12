// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct EvaluationMetrics {
    let projectID: ProjectID
    let sampleCount: Int
    let correctSampleCount: Int
    let percentCorrectForAllLabels: String
    let metricTableRows: [MetricTableRow]
}

#if DEBUG

extension EvaluationMetrics {

    static let fake = Self(
        projectID: .fakeProjectID,
        sampleCount: 500,
        correctSampleCount: 400,
        percentCorrectForAllLabels: "80%",
        metricTableRows: [
            MetricTableRow(
                label: "Apple",
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
}

#endif
