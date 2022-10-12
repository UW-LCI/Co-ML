// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import SwiftUI

/*
 * Notes that currently only subviews that take over *the full screen* of the app
 * are included as formal routes in the Navigation stack. For the other pages
 * of the app, see the enum ProjectPage, rendered in ProjectPage. ProjectPage
 * was removed from the Navigation stack to help solve some redraw issues, in at
 * least a temporary fix.
 */
enum ProjectFullScreenRoute: Hashable {
    /// camera
    case cameraPage(projectID: ProjectID, settings: CameraSettings)

    /// detail pages for labels and samples

    case labelDetailPage(projectID: ProjectID, labelAnnotation: LabelAnnotation, dataType: DataType, imageNamespace: Namespace.ID)
}

#if DEBUG

extension ProjectFullScreenRoute {
    static let fakeCameraRoute: Self = .cameraPage(
        projectID: .fakeProjectID,
        settings: .default
    )
}

#endif
