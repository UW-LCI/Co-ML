// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

struct EvaluationRepositoryInfo {
    let projectID: ProjectID
    let isModelOutOfDate: Bool
    var sortedLabels: [LabelAnnotation]
    var imagesByLabelID: [LabelID: [EvaluatedImage]]

    /// Returns the `sortedLabels` array joined with the sample count for each label.
    var labelsWithSampleCount: [LabelWithSampleCount] {
        // Since it is a requirement that _all evaluations must be completed_ when yielding an
        // `EvaluationRepositoryInfo` instance, we can just query our `imagesByLabelID` count to yield a sample count
        // for each of our sorted labels.
        sortedLabels.map {
            LabelWithSampleCount(label: $0,
                                 sampleCount: imagesByLabelID[$0.id]?.count ?? 0)
        }
    }

    var briefDescription: String {
        "\(sortedLabels.count) labels, \(imageCount) images, \(numPredictions) predictions, projectID: \(projectID)"
    }

    var imageCount: Int {
        allImages.count
    }

    var numPredictions: Int {
        allImages.filter(\.hasPrediction).count
    }

    var correctSampleCount: Int {
        numCorrectPredictions(with: allImages)
    }

    var totalPercentCorrect: String {
        localizedPercentCorrect(with: allImages)
    }

    var metricTableRows: [MetricTableRow] {
        sortedLabels.map(metricTableRow(labelAnnotation:))
    }

    var allImages: [EvaluatedImage] {
        imagesByLabelID.values.flatMap { $0 }
    }

    // MARK: - Private

    private func localizedPercentCorrect(with images: [EvaluatedImage]) -> String {
        return percentCorrect(with: images)?.localizedConfidenceDisplayText ?? ""
    }

    private func metricTableRow(labelAnnotation: LabelAnnotation) -> MetricTableRow {
        guard let images = imagesByLabelID[labelAnnotation.id] else {
            return MetricTableRow(label: labelAnnotation.labelString, percentCorrect: "0%", count: 0)
        }

        let localizedPercentCorrect = localizedPercentCorrect(with: images)

        return MetricTableRow(label: labelAnnotation.labelString,
                              percentCorrect: localizedPercentCorrect,
                              count: images.count)
    }

    private func percentCorrect(with images: [EvaluatedImage]) -> Double? {
        guard !images.isEmpty else {
            return nil
        }
        return Double(numCorrectPredictions(with: images)) / Double(images.count)
    }

    private func numCorrectPredictions(with images: [EvaluatedImage]) -> Int {
        images.filter(\.isCorrect).count
    }
}

extension EvaluationMetrics {
    init(projectID: ProjectID, evaluationRepositoryInfo: EvaluationRepositoryInfo) {
        self = EvaluationMetrics(projectID: projectID,
                                 sampleCount: evaluationRepositoryInfo.imageCount,
                                 correctSampleCount: evaluationRepositoryInfo.correctSampleCount,
                                 percentCorrectForAllLabels: evaluationRepositoryInfo.totalPercentCorrect,
                                 metricTableRows: evaluationRepositoryInfo.metricTableRows)
    }
}
