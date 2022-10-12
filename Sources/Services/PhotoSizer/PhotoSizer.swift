// Copyright 2026 Apple Inc. All rights reserved.

import Foundation
import UIKit

protocol PhotoSizer: Sendable {

    func scaleAndCrop(image: UIImage) -> UIImage
}
