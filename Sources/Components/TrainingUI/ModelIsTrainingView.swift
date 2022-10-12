// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ModelIsTrainingView: View {
    @State var isAnimating = false

    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemGroupedBackground)

            VStack {
                Text(.yourModel)
                    .trainingCardTitle()

                Spacer()
                ZStack {
                    Image(systemName:  "square.stack.3d.up")
                        .trainingCardMainImage()
                        .foregroundStyle(.secondary)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .trainingCardMainImage(height: 140)
                        .fontWeight(.thin)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(Angle(degrees: self.isAnimating ? 360.0 : 0.0))
                        .animation(foreverAnimation, value: self.isAnimating)
                        .onAppear {
                            self.isAnimating = true
                        }
                }
                Spacer()

                Button {
                    assertionFailure("Disabled button")
                } label: {
                    Label(.previewModel, systemImage: "camera.fill")
                        .padding(.horizontal, 40)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
                .padding(.bottom, .trainingCard.largePadding)
            }
        }
    }

    private var foreverAnimation: Animation {
        Animation.linear(duration: 2.5).repeatForever(autoreverses: false)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    ModelIsTrainingView()
        .trainingCardPreviewStyle()
}

#endif
