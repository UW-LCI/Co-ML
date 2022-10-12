// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ModelOutOfDateBar: View {
    var alignment: HorizontalAlignment = .center
    var navigateToTrainingPage: (() -> Void)?

    var body: some View {
        HStack {
            if alignment != .leading {
                Spacer()
            }

            Image(systemName: "exclamationmark.circle.fill")
            Text(updateAvailableString)
                .onTapGesture {
                    navigateToTrainingPage?()
                }

            if alignment != .trailing {
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    var updateAvailableString: AttributedString {
        let retrainVerbPhrase = String(localized: .retrainYourModel)

        var result = AttributedString(localized: .updateAvailableOnNewData(retrainVerbPhrase))
        if navigateToTrainingPage == nil {
            return result
        }
        if let verbPhraseRange = result.range(of: retrainVerbPhrase) {
            result[verbPhraseRange].foregroundColor = .accentColor
        }
        return result
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack {

        ModelOutOfDateBar { // CTA link
            print("retrain")
        }

        ModelOutOfDateBar() // No CTA link.

        Spacer()
    }
}

#endif
