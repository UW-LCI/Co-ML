// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// Extensions to the Projects Array to express user messages about deletion and selection
extension [Project] {
    var projectsSelectedString: String {
        .init(localized: .projectsSelectedHeading(count))
    }

    /// Used in the delete confirmation as well as the Voiceover hint for the delete button
    var deleteConfirmationTitle: String {
        if count > 1 {
            return defaultDeleteConfirmationTitle
        }

        guard let onlyProject = first else {
            return defaultDeleteConfirmationTitle
        }

        if onlyProject.shareState == .shareRecipient {
            return String(localized: .leave(onlyProject.title))
        }

        return String(localized: .delete(onlyProject.title))
    }

    var deleteConfirmationMessage: String {
        if count > 1 {
            return defaultDeleteConfirmationMessage
        }

        switch first?.shareState {
        case .shareOwner:
            return String(localized: .allTheDataInYourProjectWillBeDeletedEtc)

        case .shareRecipient:
            return String(localized: .thisProjectWillBeRemovedFromYourGalleryEtc)

        case .notShared, .unknown, .none:
            return defaultDeleteConfirmationMessage
        }
    }

    // MARK: - Private

    private var defaultDeleteConfirmationTitle: String {
        .init(localized: .deleteProjectsAlertHeading(count))
    }

    private var defaultDeleteConfirmationMessage: String {
        .init(localized: .deleteProjectsConfirmationMessage)
    }
}

extension String {
    static func projectsSelectedString(for projects: [Project]) -> Self {
        projects.projectsSelectedString
    }

    static func deleteConfirmationTitle(for projects: [Project]) -> Self {
        projects.deleteConfirmationTitle
    }

    static func deleteConfirmationMessage(for projects: [Project]) -> Self {
        projects.deleteConfirmationMessage
    }
}
