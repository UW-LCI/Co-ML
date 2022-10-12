// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import SwiftUI

struct ProjectsGalleryView: View {
    @ObservedObject var projectsViewModel: ProjectGalleryViewModel

    /// Propose to user to delete these projects
    @State private var proposeDelete: (showing: Bool, projects: [Project]?) = (false, nil)

    @State private var editMode: EditMode = .inactive
    @State private var isShowingProjectNamingSheet = false

    let goToProjectDetails: (_ project: Project) -> Void

    /// Deletion model
    /// 1. User selects projects: recorded by viewModel.selectedProjects
    /// 2. User taps delete: recorded by proposeDelete.projects
    /// 3. Alert appears, proposeDelete.projects captured by Alert
    /// 4. User confirms in alert: captured value sent to deletion engine
    /// Time to show the delete alert
    func proposeToDelete(projects: [Project]) {
        proposeDelete = (true, projects)
    }

    init(
        viewModel: ProjectGalleryViewModel,
        isSelectingProjects: Bool = false,
        goToProjectDetails: @escaping (Project) -> Void
    ) {
        self.projectsViewModel = viewModel
        self.goToProjectDetails = goToProjectDetails
        self.editMode = isSelectingProjects ? .active : .inactive
    }

    var body: some View {
        VStack {
            switch projectsViewModel.projectListState {
            case .loading:
                ProgressView()
            case .showingResults(let projects) where projects.isEmpty:
                NoProjectsView {
                    Task(priority: .userInitiated) {
                        await projectsViewModel.createProject()
                    }
                }
            case .showingResults(let tileViewStates):
                ZStack(alignment: .bottom) {
                    ProjectGridView(
                        isEditingProjects: editMode.isEditing,
                        tileViewStates: tileViewStates,
                        imageFetchRepository: projectsViewModel.imageFetchRepository,
                        showLoadingProject: projectsViewModel.showLoadingProject,
                        deleteProject: { singleProjectToDelete in
                            proposeToDelete(projects: [singleProjectToDelete])
                        },
                        goToProjectDetails: goToProjectDetails,
                        selection: $projectsViewModel.selection
                    )
                }

            case .showingError(let error):
                Text(error.localizedDescription)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !projectsViewModel.models.isEmpty {
                    EditButton()
                        .padding()
                        .environment(\.editMode, $editMode)
                        .onChange(of: editMode) { newValue in
                            if !newValue.isEditing {
                                projectsViewModel.cancelSelection()
                            }
                        }
                }

                if editMode.isEditing {
                    Button(role: .destructive) {
                        proposeToDelete(projects: projectsViewModel.selectedProjects)
                    } label: {
                        Label(.deleteProjects, systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .padding()
                    .disabled(projectsViewModel.deleteButtonDisabled)
                } else {
                    Button {
                        os_log(.info, "Add New Project button tapped")
                        Task(priority: .userInitiated) {
                            await projectsViewModel.createProject()
                        }
                    } label: {
                        Label(.addNewProject, systemImage: "plus")
                            .contentShape(Rectangle())
                    }
                    .padding()
                    .disabled(projectsViewModel.projectListState.isLoading)
                }
            }
        }
        // MARK: Title and Menu
        .navigationTitle(
            editMode.isEditing
            ? projectsViewModel.selectedProjects.projectsSelectedString
            : String(localized: .myProjects)
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleMenu {
            Button {
                Task(priority: .userInitiated) {
                    editMode = .inactive
                    await projectsViewModel.updateProjects()
                }
            } label: {
                Label(.refresh, systemImage: "arrow.2.squarepath")
            }
            .disabled(editMode.isEditing)
        }
        .toolbarRole(.navigationStack)

        // MARK: Alerts and Sheets
        .alert(
            proposeDeleteProjectsAlertTitle,
            isPresented: $proposeDelete.showing,
            presenting: $proposeDelete.projects) { $projectsToDelete in
                Button(role: .destructive) {
                    if let projects = projectsToDelete {
                        projectsViewModel.delete(projects: projects)
                        editMode = .inactive
                    }
                    proposeDelete = (false, nil)
                } label: {
                    Label(.delete, systemImage: "trash")
                }
            } message: { $projectsToDelete in
                if let projectsToDelete {
                    Text(projectsToDelete.deleteConfirmationMessage)
                }
            }

        .alert(
            projectsViewModel.modalErrorType.alertTitle,
            isPresented: $projectsViewModel.showingModalAlert,
            presenting: $projectsViewModel.modalErrorType,
            actions: { _ in
                EmptyView()
            }, message: { $errorType in
                Text(errorType.alertMessage)
            })

        .task {
            await projectsViewModel.monitorProjectGalleryChanges()
        }
        .task {
            await projectsViewModel.monitorShareAcceptance()
        }
        .task {
            await projectsViewModel.monitorCloudKitSetup()
        }
    }

    private var proposeDeleteProjectsAlertTitle: String {
        let projects = proposeDelete.projects ?? []
        return projects.deleteConfirmationTitle
    }
}

/// Extension facilitating localized string key extraction.
extension ProjectGalleryViewModel.ModalErrorType {

    var alertTitle: LocalizedStringResource {
        switch self {
        case .none:
            ""
        case .failedToCreateProject:
            .createProjectAlertTitle
        case .failedToDeleteProjects:
            .deleteProjectsAlertTitle
        }
    }

    var alertMessage: String {
        switch self {
        case .none:
            return ""

        case .failedToCreateProject:
            return String(localized: .failedToCreateANewProject)

        case .failedToDeleteProjects(let count):
            return String(localized: .failedToDeleteProjects(count))
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Gallery") {

    NavigationStack {
        ProjectsGalleryView(viewModel: ProjectGalleryViewModel(
            projectStore: .fake,
            imageFetchRepository: ImageFetchRepositoryFake()
        )) { action in
            print("Action", action)
        }
    }
}

#Preview("Gallery Selecting") {
    NavigationStack {
        ProjectsGalleryView(viewModel: ProjectGalleryViewModel(
            projectStore: .fake,
            imageFetchRepository: ImageFetchRepositoryFake()
        ), isSelectingProjects: true) { action in
            print("Action", action)
        }
    }
}

#Preview("Failed to delete project plurals") {
    VStack {
        Text(ProjectGalleryViewModel.ModalErrorType.failedToDeleteProjects(count: 0).alertMessage)
        Text(ProjectGalleryViewModel.ModalErrorType.failedToDeleteProjects(count: 1).alertMessage)
        Text(ProjectGalleryViewModel.ModalErrorType.failedToDeleteProjects(count: 2).alertMessage)
    }
}

#Preview("Projects selected plurals") {
    VStack {
        Text(verbatim: .projectsSelectedString(for: []))
        Text(verbatim: .projectsSelectedString(for: .oneProjectArray))
        Text(verbatim: .projectsSelectedString(for: .twoProjectArray))
    }
}

#Preview("Delete confirmation plurals") {
    VStack {
        Text(verbatim: .deleteConfirmationTitle(for: []))
        Text(verbatim: .deleteConfirmationTitle(for: .oneProjectArray))
        Text(verbatim: .deleteConfirmationTitle(for: .twoProjectArray))
    }
}

#Preview("Delete confirmation message plurals") {
    VStack {
        Text(verbatim: .deleteConfirmationMessage(for: []))
        Text(verbatim: .deleteConfirmationMessage(for: .oneProjectArray))
        Text(verbatim: .deleteConfirmationMessage(for: .twoProjectArray))
        Divider()
        Text(verbatim: .deleteConfirmationMessage(for: .ownedProjectAray))
        Text(verbatim: .deleteConfirmationMessage(for: .receivedProjectArray))
    }
}

private extension [Project] {
    static let oneProjectArray: Self = [
        .init(
            id: .fakeProjectID,
            title: "Project 100",
            createdAt: .date1
        )
    ]

    static let ownedProjectAray: [Project] = [
        .init(
            id: .fakeProjectID2,
            title: "Project 101",
            createdAt: .date1,
            shareState: .shareOwner
        )
    ]

    static let receivedProjectArray: [Project] = [
        .init(
            id: .fakeProjectID3,
            title: "Project 102",
            createdAt: .date2,
            shareState: .shareRecipient
        )
    ]

    static let twoProjectArray: [Project] = [
        .init(
            id: .fakeProjectID4,
            title: "Project 104",
            createdAt: .date1
        ),
        .init(
            id: .fakeProjectID5,
            title: "Project 105",
            createdAt: .date1
        )
    ]
}

#endif
