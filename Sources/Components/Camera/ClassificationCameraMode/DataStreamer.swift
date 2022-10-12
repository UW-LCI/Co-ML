// Copyright 2026 Apple Inc. All rights reserved.

import UIKit

protocol DataStreamer: Actor {
    func streamData() async -> AsyncThrowingStream<[Observation], Error>
    func setInputImage(_ image: UIImage) async
}
