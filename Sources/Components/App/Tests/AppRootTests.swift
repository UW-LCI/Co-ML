// Copyright 2026 Apple Inc. All rights reserved.

import XCTest
@testable import CoMLApp

@MainActor
final class AppRootTests: XCTestCase {
    let id = UUID(uuidString: "cf7a5a0d-0a4a-4b95-9ebb-dd921f58b41e")!

    lazy private var projects: [Project] = [
        Project(
            id: id,
            title: "Dancehall Poses",
            createdAt: Date()
        ),
        Project(
            id: UUID(),
            title: "Tropical Fruits",
            createdAt: Date()
        )
    ]

    lazy private var projectsViewModel: ProjectGalleryViewModel = {
        let tileViewStates = projects.map { ProjectTileViewState(project: $0, thumbnails: [], totalSampleCount: 0) }
        let store = ProjectListStoreFake(gridItems: tileViewStates)

        return ProjectGalleryViewModel(
            projectStore: store,
            imageFetchRepository: ImageFetchRepositoryFake()
        )
    }()

    func testProjectCreationResultsInExactlyOneProject() async throws {
        let viewModel = ProjectGalleryViewModel(
            projectStore: ProjectListStoreFake(),
            imageFetchRepository: ImageFetchRepositoryFake()
        )

        await viewModel.createProject()
        await viewModel.updateProjects()

        switch viewModel.projectListState {
        case .showingResults(let results) where results.isEmpty:
            XCTFail("Error occurred, should not be empty")
        case .showingResults(let projects):
            XCTAssertTrue(projects.count == 1, "Total should be 1 project")
        case .showingError(let error):
            XCTFail("Error occurred: \(error)")
        case .loading:
            XCTFail("Error occurred, should not reach this state")
        }
    }

    func testToggleSelectionTogglesProject() async {
        await projectsViewModel.updateProjects()
        projectsViewModel.selection.toggle(id)

        let selectedProjects = projectsViewModel.selectedProjects
        XCTAssertEqual(selectedProjects.count, 1, "There should only be one selected project")
        XCTAssertEqual(selectedProjects.first?.id, id, "Selected id should be the same as the one passed in.")
    }

    func testCancelSelectionShouldDeselectSelectedProjects() async {
        await projectsViewModel.updateProjects()
        projectsViewModel.selection.toggle(id)
        projectsViewModel.cancelSelection()

        XCTAssertEqual(projectsViewModel.selectedProjects.count, 0)
    }
}
