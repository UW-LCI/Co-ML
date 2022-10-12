// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

struct AddImagesButton: View {

    let openCameraLink: ProjectFullScreenRoute
    let photosAppImport: () -> Void
    let filesAppImport: () -> Void

    var body: some View {
        Menu {
            Button(action: photosAppImport) {
                Label(.importPhotos, systemImage: "photo")
            }
            Button(action: filesAppImport) {
                Label(.importFiles, systemImage: "folder.fill")
            }
            NavigationLink(value: openCameraLink) {
                Label(.openCamera, systemImage: "camera.fill")
            }
        } label: {
            Label(.addImages, systemImage: "plus")
                .padding(6)
                .padding(.horizontal, 8)
                .background(.blue.opacity(0.14))
        }
        .font(.callout)
        .clipShape(Capsule(style: .continuous))
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    AddImagesButton(openCameraLink: .fakeCameraRoute) {
        print("Import from photos app")
    } filesAppImport: {
        print("Import from files app")
    }
}

#endif
