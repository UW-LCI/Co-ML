// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Dictionary extension providing functionality that allows conversion
/// from `[LabelID: [LabeledImage]]` to `[LabelID: [EvaluatedImage]]`
extension Dictionary where Key == LabelID, Value == [LabeledImageID] {

    /// Maps all `LabeledImages` in `self` to `EvaluatedImages` with prediction `nil`
    var withNoneEvaluated: [LabelID: [EvaluatedImage]] {
        evaluated(predictionsByImageID: [:], labels: [])
    }

    /// Given a dictionary of predictions by labeled image ID, converts the receiver to a dictionary of
    /// `[LabeledImageID: [EvaluatedImage]]` where `Predictions` in the result are joined from the given
    /// lookup table.
    func evaluated(predictionsByImageID: [LabeledImageID: Prediction],
                   labels: [LabelAnnotation]
    ) -> [LabelID: [EvaluatedImage]] {
        var result: [LabelID: [EvaluatedImage]] = [:]
        for (labelID, labeledImageIDs) in self {
            result[labelID] = labeledImageIDs.toSortedEvaluatedImages(with: predictionsByImageID, labels: labels)
        }
        return result
    }
}

// MARK: - Private

private extension Array<LabeledImageID> {

    /// Converts the receiver to an appropriately sorted array of evaluated images.
    /// - Parameters:
    ///   - predictionsByImageID: A dictionary of predictions by image ID.
    ///   - labels: Array of label annotations used to determine predictions' correctness.
    /// - Returns: a sorted array of `EvaluatedImages`, partitioned in the order `[incorrect, correct, unpredicted]`.
    func toSortedEvaluatedImages(with predictionsByImageID: [LabeledImageID: Prediction],
                                 labels: [LabelAnnotation]) -> [EvaluatedImage] {
        var correctImages: [EvaluatedImage] = []
        var incorrectImages: [EvaluatedImage] = []
        var noPredictionImages: [EvaluatedImage] = []

        for labeledImageID in self {

            // If there is no prediction, add the "no prediction" image.
            guard let prediction = predictionsByImageID[labeledImageID] else {
                noPredictionImages.append(EvaluatedImage(imageID: labeledImageID, predictionState: nil))
                continue
            }

            let isCorrect = prediction.isCorrect(labelID: labeledImageID.labelID, labels: labels)
            let predictionState = EvaluatedImage.PredictionState(prediction: prediction, isCorrect: isCorrect)

            if isCorrect {
                correctImages.append(EvaluatedImage(imageID: labeledImageID, predictionState: predictionState))
            } else {
                incorrectImages.append(EvaluatedImage(imageID: labeledImageID, predictionState: predictionState))
            }
        }

        return incorrectImages + correctImages + noPredictionImages
    }
}
