// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import os.log

final class TrainingAnalyticsServiceImpl: TrainingAnalyticsService {
    private let internalService: TrainingAnalyticsServiceInternal

    init(projectID: ProjectID) {
        internalService = TrainingAnalyticsServiceInternal(projectID: projectID)
    }

    // MARK: - TrainingAnalyticsService

    func logTrainingStarted(labelCount: Int, sampleCount: Int) {
        let timeStarted = CFAbsoluteTimeGetCurrent()
        Task {
            await internalService.trainingStarted(at: timeStarted,
                                                  labelCount: labelCount,
                                                  sampleCount: sampleCount)
        }
    }

    func logTrainingFailed() {
        let timeFinished = CFAbsoluteTimeGetCurrent()
        Task {
            if let log = await internalService.trainingFailed(at: timeFinished) {
                AnalyticsSendEventLazy(.trainingEventName) {
                    log.eventPayload
                }
            }
        }
    }

    func logTrainingFinished() {
        let timeFinished = CFAbsoluteTimeGetCurrent()
        Task {
            if let log = await internalService.trainingFinished(at: timeFinished) {
                AnalyticsSendEventLazy(.trainingEventName) {
                    log.eventPayload
                }
            }
        }
    }
}

private func AnalyticsSendEventLazy(_ eventName: String, payload: @escaping () -> [String: NSObject]) {
    os_log(.info, "AnalyticsSendEventLazy(\(eventName)): \(payload())")
}

private actor TrainingAnalyticsServiceInternal {
    private struct StartConditions {
        let timeStarted: CFAbsoluteTime
        let labelCount: Int
        let sampleCount: Int
    }

    let projectID: ProjectID

    private var trainingStartConditions: StartConditions?

    init(projectID: ProjectID) {
        self.projectID = projectID
    }

    func trainingStarted(at timeStarted: CFAbsoluteTime, labelCount: Int, sampleCount: Int) {
        trainingStartConditions = StartConditions(timeStarted: timeStarted,
                                                  labelCount: labelCount,
                                                  sampleCount: sampleCount)
    }

    func trainingFailed(at timeFinished: CFAbsoluteTime) -> TrainingAnalyticsLog? {
        guard let trainingStartConditions else {
            os_log(.error, "Training needs to start before failing")
            return nil
        }
        let elapsedTime = timeFinished - trainingStartConditions.timeStarted
        return .imageClassifierLog(
            successful: false,
            elapsedTime: elapsedTime,
            labelCount: trainingStartConditions.labelCount,
            sampleCount: trainingStartConditions.sampleCount)
    }

    func trainingFinished(at timeFinished: CFAbsoluteTime) -> TrainingAnalyticsLog? {
        guard let trainingStartConditions else {
            os_log(.error, "Training needs to start before finishing")
            return nil
        }
        let elapsedTime = timeFinished - trainingStartConditions.timeStarted
        return .imageClassifierLog(
            successful: true,
            elapsedTime: elapsedTime,
            labelCount: trainingStartConditions.labelCount,
            sampleCount: trainingStartConditions.sampleCount)
    }
}
