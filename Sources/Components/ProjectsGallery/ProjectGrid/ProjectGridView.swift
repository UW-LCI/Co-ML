// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import SwiftUI

extension Set {
    /// Removes `element` if present, or adds it if absent.
    mutating func toggle(_ element: Element) {
        formSymmetricDifference([ element ])
    }
}

@MainActor
struct ProjectGridView: View {
    @State private var isShowingDeleteAlert = false
    @State private var projectToDelete: Project?
    var isEditingProjects: Bool
    var tileViewStates: [ProjectTileViewState]
    let imageFetchRepository: ImageFetchRepository
    let showLoadingProject: Bool

    var deleteProject: (Project) -> Void
    var goToProjectDetails: (Project) -> Void

    @Binding var selection: Set<ProjectID>

    private let columns = [
        GridItem(.adaptive(
            minimum: ProjectUIConstants.projectsListGridItemWidth,
            maximum: ProjectUIConstants.projectsListGridItemWidth
        ))
    ]

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: .tile.spacing) {
                    if showLoadingProject {
                        ZStack(alignment: .topTrailing) {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(14)
                        .shadow(
                            color: .gray.opacity(0.07),
                            radius: 5,
                            x: 0,
                            y: 4
                        )
                    }
                    ForEach(tileViewStates) { tileViewState in
                        let isSelected = selection.contains(tileViewState.id)
                        ZStack(alignment: .topTrailing) {
                            Button {
                                if isEditingProjects {
                                    selection.toggle(tileViewState.id)
                                } else {
                                    goToProjectDetails(tileViewState.project)
                                }
                            } label: {
                                ProjectTileView(
                                    viewState: tileViewState,
                                    isSelected: isSelected,
                                    isEditing: isEditingProjects,
                                    fetchImage: imageFetchRepository.fetchImage(sampleUUID:)
                                )
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(14)
                            .shadow(
                                color: .gray.opacity(0.07),
                                radius: 5,
                                x: 0,
                                y: 4
                            )
                            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 14))
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteProject(tileViewState.project)
                                } label: {
                                    Label(.delete, systemImage: "trash")
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    // We only need to animate here when the ids of the projects change
                    .animation(.easeInOut, value: tileViewStates.map(\.id))
                }
            }
            Spacer()
            HStack {
                Spacer()

                Text(.version(bundleVersionString))
                    .padding(.trailing)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(UIColor.systemGray6))
    }

    private var bundleVersionString: String {
        Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "0.0"
    }
}

enum ProjectUIConstants {
    static let projectsListGridItemWidth: CGFloat = 246
}

// MARK: - Previews

#if DEBUG

#Preview("Not editing") {
    ProjectGridView.fake(editing: false)
}

#Preview("Editing") {
    ProjectGridView.fake(editing: true)
}

extension ProjectGridView {
    static func fake(editing: Bool) -> some View {
        NavigationStack {
            ProjectGridView(
                isEditingProjects: editing,
                tileViewStates: .fake,
                imageFetchRepository: ImageFetchRepositoryFake(),
                showLoadingProject: false,
                deleteProject: {
                    print("Delete Action \($0)")
                },
                goToProjectDetails: {
                    print("Go to project \($0)")
                },
                selection: .constant([])
            )
            .toolbar {
                // just for atmosphere
                EditButton()
            }
        }
    }
}

#endif
