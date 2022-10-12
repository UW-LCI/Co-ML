// Copyright 2026 Apple Inc. All rights reserved.

import OSLog
import SwiftUI

struct PreviewModelView: View {
    let projectID: ProjectID
    let dateLastTrained: Date
    let navigateToTestPage: () -> Void

    var body: some View {
        VStack {
            Text(.yourModel)
                .trainingCardTitle()

            Text(.nowYouCanTestHowTheModelWorksInTheCamera)
                .trainingCardSubtitle()

            Spacer()
            Image(systemName: "gear.badge.checkmark")
                .trainingCardMainImage()
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.green, Color.primary)

            Spacer()

            Button {
                navigateToTestPage()
            } label: {
                Label(.testModel, systemImage: "rectangle.portrait.and.arrow.forward" )
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)

            TimelineView(.everyMinute) { _ in
                Text(.lastTrained(dateLastTrained.formatted(.relative(presentation: .named))))
                    .trainingCardButtonCaption()
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    PreviewModelView(
        projectID: .fakeProjectID,
        dateLastTrained: .date1
    ) {
        // No-op
    }
    .trainingCardPreviewStyle()
}

#endif
