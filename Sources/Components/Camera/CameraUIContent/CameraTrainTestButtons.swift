// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct CameraTrainTestButtons: View {

    @Binding var dataType: DataType

    var body: some View {
        let train = dataType == .training
        VStack(spacing: 10) {
            Button {
                dataType = .training
            } label: {
                Text(.trainCameraDestination)
                    .font(.body.lowercaseSmallCaps())
                    .foregroundColor(train ? .yellow : .white)
                    .padding(4)
                    .padding(.horizontal, 8)
                    .background(.black.opacity(train ? 0.40 : 0.0))
                    .cornerRadius(16)
            }
            Button {
                dataType = .testing
            } label: {
                Text(.testCameraDestination)
                    .font(.body.lowercaseSmallCaps())
                    .foregroundColor(train ? .white : .yellow)
                    .padding(4)
                    .padding(.horizontal, 8)
                    .background(.black.opacity(train ? 0.0 : 0.40))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Training") {
    CameraTrainTestButtons(
        dataType: .constant(.training)
    )
}

#Preview("Testing") {
    CameraTrainTestButtons(
        dataType: .constant(.testing)
    )
}

#endif
