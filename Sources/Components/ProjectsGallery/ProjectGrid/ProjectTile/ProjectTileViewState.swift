// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct ProjectTileViewState: Identifiable {
    enum ThumbnailType {
        case image(UUID)
        case placeholder
    }

    let project: Project
    let thumbnails: [ThumbnailType]
    let totalSampleCount: Int

    // MARK: - Identifiable

    var id: ProjectID {
        project.id
    }

    // MARK: - Computed properties

    var isShared: Bool {
        project.isShared
    }

    var labelNamesDisplayString: String {
        ListFormatter.localizedString(byJoining: project.labelNames)
    }

    var createdAtFormatted: String {
        project.createdAt.formatted(date: .long, time: .shortened)
    }

    var projectTitle: String {
        project.title
    }
}

#if DEBUG

extension [ProjectTileViewState] {
    static let fake: Self = [
        .fakeNotEditing,
        .fakeEditingNotSelected,
        .fakeEditingSelected
    ]
}

extension ProjectTileViewState {
    static let fakeNotEditing = ProjectTileViewState(project: .sampleData.animals, thumbnails: [], totalSampleCount: 0)

    static let fakeEditingNotSelected = ProjectTileViewState(project: .sampleData.empty, thumbnails: [], totalSampleCount: 1)

    static let fakeEditingSelected = ProjectTileViewState(project: .sampleData.houses, thumbnails: [], totalSampleCount: 10)

    static func fakeWithRandomProject() -> ProjectTileViewState {
        .init(project: .sampleData.randomProject(), thumbnails: [], totalSampleCount: 10)
    }
}

#endif
