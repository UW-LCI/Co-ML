// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct CameraRecentPhotosStream: View {

    let label: String
    let imageIDs: [LabeledImageID]
    let fetchImage: (UUID) async throws -> UIImage
    let showImageAction: (LabeledImageID) -> Void

    var body: some View {
        ScrollView(.vertical) {
            VStack (spacing: .tile.spacing) {
                // Enumerated is safe here because I just want to read the position to the human
                ForEach(Array(imageIDs.enumerated()), id: \.element) { element in
                    let (offset, imageID) = element
                    Button {
                        showImageAction(imageID)
                    } label: {
                        SampleImageView {
                            try await fetchImage(imageID.sampleID)
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(width: .tile.width, height: .tile.width)
                        .accessibilityLabel(.picture)
                        .accessibilityValue(.voiceOverLabelNumberOfTotal(label, offset + 1, imageIDs.count))
                    }
                    .accessibilityInputLabels([
                        String(localized: .picture(offset + 1))
                    ])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(.recentPictures)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    CameraRecentPhotosStream(
        label: "Sausage",
        imageIDs: SampleDetailViewPreviewTestData.images.map({ $0.id }),
        fetchImage: ImageFetchRepositoryFake.fetchImage
    ) { imageID in
        print("Show image '\(imageID)'.")
    }
}

#endif
