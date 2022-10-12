// Copyright 2026 Apple Inc. All rights reserved.

import Foundation

struct TrainingViewState: Sendable {

    let projectID: ProjectID
    var projectName: String

    var projectPanelState: TrainingProjectPanel.State = .loading
    var modelPanelState: TrainingModelPanel.State = .loading

    var isTraining: Bool = false

    var errorDuringTraining: String?
}

#if DEBUG

extension TrainingViewState {
    static func fake(
        projectPanelState: TrainingProjectPanel.State,
        modelPanelState: TrainingModelPanel.State
    ) -> Self {
        .init(
            projectID: .fakeProjectID,
            projectName: "Test Project",
            projectPanelState: projectPanelState,
            modelPanelState: modelPanelState
        )
    }
}

#endif
