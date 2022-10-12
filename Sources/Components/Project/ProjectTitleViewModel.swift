// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Combine
import os.log
import SwiftUI

@MainActor
final class ProjectTitleViewModel: ObservableObject {
    private let projectID: UUID
    private let databaseStorageService: any DatabaseStorageService
    private var notificationObserver: Cancellable?

    @Published private(set) var currentTitle: String

    var editableTitle: Binding<String> {
        Binding<String> {
            self.currentTitle
        } set: { newTitle in
            self.renameProject(newName: newTitle)
        }
    }

    init(
        projectID: UUID,
        initialTitle: String,
        databaseStorageService: any DatabaseStorageService
    ) {
        self.projectID = projectID
        self.currentTitle = initialTitle
        self.databaseStorageService = databaseStorageService

        self.notificationObserver = NotificationCenter.default.combineNotification(projectID: projectID) { [weak self] in
            try? await self?.reloadProjectTitle()
        }
    }

    /// Rename a project.
    ///
    /// - Parameter newName: Updated name.
    func renameProject(newName: String) {
        let validatedName = newName.validated(previous: currentTitle)

        if validatedName == currentTitle {
            os_log(.info, "Reverting from \(newName) to \(self.currentTitle)")
            // By assigning the same value, the label editor is refreshed and discards any working value.
            currentTitle = currentTitle
            return
        }

        os_log(.info, """
            Renaming Project Title to "\(validatedName)", from "\(self.currentTitle)" (working) "\(self.editableTitle.wrappedValue)"
        """)

        Task(priority: .userInitiated) {
            do {
                try await databaseStorageService.renameProject(id: projectID, newName: validatedName)
            } catch {
                os_log("Error renaming project: \(error.localizedDescription)")
            }
        }
    }

    /// Reload and update project title.
    ///
    /// - Throws: Fetch error.
    private func reloadProjectTitle() async throws {
        currentTitle = try await databaseStorageService.fetchProjectTitle(id: self.projectID)
    }
}
