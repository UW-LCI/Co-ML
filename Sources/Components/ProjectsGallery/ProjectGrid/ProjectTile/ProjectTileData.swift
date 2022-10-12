// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit

struct ProjectTileData: Identifiable {
    var id: UUID { projectID }
    var projectID: ProjectID
    var name: String
    var thumbnail: UIImage
    var trainingSampleCount: Int
}

