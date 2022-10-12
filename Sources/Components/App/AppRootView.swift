// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

@MainActor
public struct AppRootView: View {

    // Services
    private let databaseStorageService: DatabaseStorageService
    private let imageFetchRepository: ImageFetchRepository

    @State private var viewingProject: Project?

    @StateObject private var projectGalleryViewModel: ProjectGalleryViewModel

    public init() {
        self.databaseStorageService = CoreDataDatabaseStorageService.shared
        let imageFetchRepository = ImageFetchRepositoryImpl(databaseStorageService: databaseStorageService)
        self.imageFetchRepository = imageFetchRepository

        let projectListStore = ProjectListStore(databaseStorageService: databaseStorageService)

        _projectGalleryViewModel = StateObject(wrappedValue: ProjectGalleryViewModel(
            projectStore: projectListStore,
            imageFetchRepository: imageFetchRepository
        ))

        // Prevents (annoying) swipe animation when NavigationStack changes route
        UINavigationBar.setAnimationsEnabled(false)
    }

    public var body: some View {
        NavigationStack {
            if let project = viewingProject {
                projectView(project: project)
            } else {
                ProjectsGalleryView(viewModel: projectGalleryViewModel) { project in
                    viewingProject = project
                }
            }
        }
        .iCloudAlertPresenter() // Monitors iCloud health
    }

    @ViewBuilder
    private func projectView(project: Project) -> some View {
        ProjectRootView(
            wrappedValue: ProjectRootViewModel(
                project: project,
                databaseStorageService: databaseStorageService,
                imageFetchRepository: imageFetchRepository,
                exitProject: {
                    viewingProject = nil
                }
            ),
            wrappedTitleViewModel: ProjectTitleViewModel(
                projectID: project.id,
                initialTitle: project.title,
                databaseStorageService: databaseStorageService
            )
        )
        .id(project.id)
    }
}
