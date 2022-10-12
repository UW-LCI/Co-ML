// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationDescriptiveLabel: View {
    let state: EvaluationDescriptiveLabelState

    var body: some View {
        Label {
            switch state {
            case let .correct(labelName):
                Text(.theModelCorrectlyClassifiedThisImage(labelName))

            case let .incorrect(wrongLabelName, expectedLabelName):
                Text(.theModelIncorrectlyClassifiedThisImageAs(expectedLabelName, wrongLabelName))
            }

        } icon: {
            Image(systemName: state.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(state.isCorrect ? .green : .red)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack(alignment: .leading) {

        Text(verbatim: "Correct")
            .font(.title)
            .padding(.top)

        EvaluationDescriptiveLabel(
            state: .correct(
                labelName: "Broccoli"
            )
        )

        Text(verbatim: "Incorrect")
            .font(.title)
            .padding(.top)

        EvaluationDescriptiveLabel(
            state: .incorrect(
                wrongLabelName: "Bean",
                expectedLabelName: "Broccoli"
            )
        )

        Spacer()
    }
}

#endif
