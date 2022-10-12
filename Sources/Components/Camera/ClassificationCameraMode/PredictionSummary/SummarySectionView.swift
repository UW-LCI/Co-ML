// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct SummarySectionView: View {
    let state: PredictionSummaryViewState

    var body: some View {
        Group {
            Text(state.predictionConfidencePrefix) + Text(state.predictedLabel)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color(UIColor.tertiarySystemBackground))
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    SummarySectionView(
        state: .init(
            image: UIImage(systemName: "tornado")!,
            observations: .fakeObservationData,
            currentLabels: .fakeLabels
        )
    )
}

#endif
