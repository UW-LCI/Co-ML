// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct NoProjectsView: View {
    let createProjectAction: () -> Void

    var body: some View {
        VStack {

            HStack(alignment: .bottom, spacing: 20) {
                Image(systemName: "photo")
                    .welcomeImageIcon()
                    .foregroundStyle(Color.image)

                Image(systemName: "camera.fill")
                    .welcomeImageIcon()
                    .foregroundStyle(Color.camera)
                    .padding(.bottom, 35)

                Image(systemName: "list.bullet.rectangle.fill")
                    .welcomeImageIcon()
                    .foregroundStyle(Color.list)
            }

            Text(.startBuildingYourFirstImageClassifier)
                .font(.title)
                .padding()

            Button {
                createProjectAction()
            } label: {
                Label(.createProject, systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6))
        .ignoresSafeArea(.all)
    }
}

extension Image {
    func welcomeImageIcon() -> some View {
        self.resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 45)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NoProjectsView {
        print("Create project action")
    }
}

#endif
