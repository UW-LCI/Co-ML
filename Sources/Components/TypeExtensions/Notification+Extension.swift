// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Combine

extension NotificationCenter {
    func post(projectID: UUID) {
        let changedProjectID: Set<UUID> = Set([projectID])
        post(projectIDs: changedProjectID)
    }

    func post(projectIDs: Set<ProjectID>) {
        post(name: .projectsUpdated, object: nil, userInfo: [CoreDataStackImpl.CoreDataStrings.projectIDKey: projectIDs])
    }

    func notifications(projectID: UUID) -> AsyncFilterSequence<Notifications> {
        notifications(named: .projectsUpdated)
            .filter { notification in
                guard let userInfo = notification.userInfo else {
                    return false
                }
                if let updatedProjectIDs = userInfo[CoreDataStackImpl.CoreDataStrings.projectIDKey] as? Set<UUID>,
                   updatedProjectIDs.contains(projectID) {
                    return true
                } else {
                    return false
                }
            }
    }

    func combineNotification(projectID: UUID, onNotification: @escaping () async -> Void) -> Cancellable {
        self.publisher(for: .projectsUpdated)
        .filter { notification in
            guard let userInfo = notification.userInfo else {
                return false
            }
            if let updatedProjectIDs = userInfo[CoreDataStackImpl.CoreDataStrings.projectIDKey] as? Set<UUID>,
               updatedProjectIDs.contains(projectID) {
                return true
            } else {
                return false
            }
        }
        .throttle(for: 1.0, scheduler: RunLoop.main, latest: true)
        .sink { _ in
            Task {
                await onNotification()
            }
        }
    }
}

extension Notification.Name {
    static let cameraTappedNotification = Notification.Name("CameraButtonTapped")
    static let projectsUpdated = Notification.Name("ProjectsUpdated")
    static let acceptedShare = Notification.Name("AcceptedShare")
}
