// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

protocol TrainingAnalyticsService: Sendable {

    /// Tells the service that training started with the given label and sample count.
    func logTrainingStarted(labelCount: Int, sampleCount: Int)

    func logTrainingFailed()

    func logTrainingFinished()
}
