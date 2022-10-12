// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Struct for the CoreAnalytics log `co-ml.app.train`
struct TrainingAnalyticsLog {
    enum Modality: String {
        case imageStill = "1"
        case video = "10"
        case sound = "30"
    }

    enum TerminationType: String {
        case successful = "1"
        case error = "2"
        case paused = "3"
        case cancelled = "4"
    }

    /// The time elapsed during training, in **seconds**, with no unit. E.g. "25.03" or "0.0046789"
    let duration: String

    /// Whether training completed successfully, resulting in a CoreML model.
    let isComplete: Bool

    /// Whether this training even is a resumption of a prior, paused train.
    ///
    /// This is always false for version 1 of CoML.
    let isResumption: Bool

    /// How many labels the model is being trained on.
    let labelCount: Int

    /// How many samples were in the training set.
    let sampleCount: Int

    /// What type of data the user is working with (e.g. still photo, sound)
    let modality: Modality

    /// How the train finished (e.g. successfully made a model, stopped due to error, paused)
    let terminationType: TerminationType
}

extension TrainingAnalyticsLog {

    /// Creates an image classifier analytics log.
    /// - Parameters:
    ///   - successful: Whether training was successful.
    ///   - elapsedTime: The amount of time between the start and end of training.
    ///   - labelCount: The number of labels used for training.
    ///   - sampleCount: The number of samples used for training.
    /// - Returns: An appropriately configured analytics log.
    static func imageClassifierLog(
        successful: Bool,
        elapsedTime: CFTimeInterval,
        labelCount: Int,
        sampleCount: Int
    ) -> TrainingAnalyticsLog {
        TrainingAnalyticsLog(duration: elapsedTime.formatted(.number.precision(.fractionLength(6))),
                             isComplete: successful,
                             isResumption: false,
                             labelCount: labelCount,
                             sampleCount: sampleCount,
                             modality: .imageStill,
                             terminationType: successful ? .successful : .error)
    }
}

extension TrainingAnalyticsLog {

    /// Converts the receiver to a dictionary appropriate for forwarding to CoreAnalytics.
    var eventPayload: [String: NSObject] {
        [
            "duration": duration as NSString,
            "is_complete": isComplete as NSNumber,
            "is_resumption": isResumption as NSNumber,
            "labels": labelCount as NSNumber,
            "modality": modality.rawValue as NSString,
            "samples": sampleCount as NSNumber,
            "termination": terminationType.rawValue as NSString
        ]
    }
}
