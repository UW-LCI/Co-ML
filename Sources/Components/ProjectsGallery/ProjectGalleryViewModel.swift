// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import Combine
import CoreData
import os.log

@MainActor
class ProjectGalleryViewModel: ObservableObject {
    enum ModalErrorType {
        case none
        case failedToCreateProject
        case failedToDeleteProjects(count: Int)
    }

    // Services
    private let projectStore: ProjectsListRepository
    private let networkStatusRepository: NetworkStatusRepository
    let imageFetchRepository: ImageFetchRepository

    @Published private(set) var projectListState: ProjectListState = .loading

    @Published var modalErrorType = ModalErrorType.none
    @Published var showingModalAlert = false
    @Published var selection = Set<ProjectID>()
    @Published var showLoadingProject = false

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    var models: [ProjectTileViewState] {
        guard case let .showingResults(models) = projectListState else {
            return []
        }
        return models
    }

    var selectedProjects: [Project] {
        models.filter { selection.contains($0.id) }.map { $0.project }
    }

    var deleteDisabled: Bool {
        selectedProjectCount < 1
    }

    private var selectedProjectCount: Int {
        selection.count
    }

    var deleteButtonDisabled: Bool {
        selectedProjectCount == 0
    }

    init(projectStore: ProjectsListRepository, imageFetchRepository: ImageFetchRepository) {
        self.projectStore = projectStore
        self.imageFetchRepository = imageFetchRepository
        self.networkStatusRepository = NetworkStatusRepositoryImpl()
    }

    func loadProjects(debugCaller: String = #function) async {
        do {
            os_log(.info, "LoadProjects Requested by \(debugCaller)")
            projectListState = .showingResults(
                try await projectStore.load()
            )
        } catch {
            os_log(.info, "LoadProjects failed with error \(error)")
            projectListState = .showingError(error)
        }
    }

    func monitorProjectGalleryChanges() async {
        os_log(.debug, "Start monitoring project gallery changes.")

        // Start monitoring network status.
        await networkStatusRepository.startMonitoring()

        // Update once on appearance.
        await updateProjects()

        // Then, update whenever any project changes.
        for await notification in NotificationCenter.default.notifications(named: .projectsUpdated) {
            if showLoadingProject {
                checkStopShowingLoadingProject(notification: notification)
            }
            await updateProjects()
        }

        // Stop monitoring network status.
        await networkStatusRepository.stopMonitoring()

        os_log(.debug, "End monitoring project gallery changes.")
    }

    func monitorShareAcceptance() async {
        os_log(.debug, "Start monitoring share acceptances.")

        // Then, update whenever any project changes.
        for await _ in NotificationCenter.default.notifications(named: .acceptedShare) {
            self.showLoadingProject = true
        }

        os_log(.debug, "End monitoring share acceptances.")
    }

    func monitorCloudKitSetup() async {
        os_log(.debug, "Start monitoring cloud kit setup events.")
        for await _ in NotificationCenter.default.cloudKitSetupEventsStream() {
            os_log(.debug, "Handling cloud kit setup event.")
            await updateProjects()
        }
        os_log(.debug, "End monitoring cloud kit setup events.")
    }

    func updateProjects(debugCaller: String = #function) async {
        await loadProjects(debugCaller: debugCaller)
    }

    func createProject() async {
        let nextProjectNumber = models.count + 1
        let title = String(localized: .imageClassifier(nextProjectNumber.formatted()))
        let project = Project(id: UUID(), title: title, createdAt: Date())

        do {
            try await projectStore.create(project: project)
        } catch {
            os_log(.error, "An error occurred creating a project: \(error)")
            modalErrorType = .failedToCreateProject
            showingModalAlert = true
        }
    }

    func cancelSelection() {
        selection.removeAll()
    }

    func delete(projects: [Project]) {
        Task(priority: .userInitiated) { @MainActor in
            do {
                os_log(.info, "User requested delete of \(projects.count) projects")
                let isOnline = await networkStatusRepository.isOnline
                try await projectStore.delete(projectIDs: Set(projects.map(\.id)),
                                              isOnline: isOnline)
                cancelSelection()
            } catch {
                os_log(.error, "An error occurred deleting projects: \(error)")
                modalErrorType = .failedToDeleteProjects(count: projects.count)
                showingModalAlert = true
            }
        }
    }

    private func checkStopShowingLoadingProject(notification: Notification) {
        if let userInfo = notification.userInfo,
           let updatedProjectIDs = userInfo[CoreDataStackImpl.CoreDataStrings.projectIDKey] as? Set<UUID>,
           case let .showingResults(tileViewStates) = projectListState {
            let existingIDs = tileViewStates.map { $0.project.id }
            for updatedID in updatedProjectIDs where !existingIDs.contains(updatedID) {
                showLoadingProject = false
                return
            }
        }
    }
}

extension ProjectGalleryViewModel {

    enum ProjectListState {
        static let empty = showingResults([])
        case loading
        case showingResults([ProjectTileViewState])
        case showingError(Error)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }
    }
}

private extension NotificationCenter {

    /// Returns a sequence of 1s corresponding to observed successful CloudKitContainer "setup" events.
    /// Such events warrant a project refresh, as project share states may have changed,
    /// particularly from "unknown" to "known".
    func cloudKitSetupEventsStream() -> AsyncCompactMapSequence<NotificationCenter.Notifications, Int> {
        notifications(named: NSPersistentCloudKitContainer.eventChangedNotification).compactMap { notification in
            guard let userInfo = notification.userInfo else {
                return nil
            }
            guard let anyEvent = userInfo[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] else {
                return nil
            }
            guard let cloudEvent = anyEvent as? NSPersistentCloudKitContainer.Event else {
                return nil
            }
            guard cloudEvent.succeeded && cloudEvent.endDate != nil && cloudEvent.type == .setup else {
                return nil
            }
            os_log(.debug, "Posting cloud kit setup event \(cloudEvent)")
            return 1
        }
    }
}
