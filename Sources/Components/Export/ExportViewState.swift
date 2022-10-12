// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

/// State defining the appearance of `ExportView`
enum ExportViewState {

    case loading

    /// When no model exists on disk, or failed to load
    case unavailable

    /// Model is loaded and ready to export
    case loaded(projectInfo: ProjectInfo, exportURL: URL)
}

#if DEBUG

extension ExportViewState {
    static let fake: Self = .loaded(
        projectInfo: .fake,
        exportURL: .temporaryDirectory
    )

    static let fakeWithManyLabels: Self = .loaded(
        projectInfo: .manyLabels,
        exportURL: .temporaryDirectory
    )
}

#endif
