// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct SampleCardView: View {
    let imageID: LabeledImageID
    let fetchImage: (UUID) async throws -> UIImage
    let imageNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            SampleImageView {
                try await fetchImage(imageID.sampleID)
            }
            .aspectRatio(contentMode: .fit)
            .cornerRadius(.tile.cornerRadius)
            .matchedGeometryEffect(id: imageID, in: imageNamespace)
            .frame(width: .tile.width, height: .tile.height)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    SampleCardPreviewView(imageID: .fakeApple1id)
}

struct SampleCardPreviewView: View {
    let imageID: LabeledImageID

    @Namespace private var imageNamespace

    var body: some View {
        SampleCardView(
            imageID: imageID,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            imageNamespace: imageNamespace,
            action: {
                print("Sample card view action.")
            }
        )
    }
}

#endif
