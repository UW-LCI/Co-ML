// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct MetricsSummaryList: View {

    let metrics: [MetricTableRow]

    var body: some View {
        List {
            Section {
                ForEach(metrics) { metrics in
                    HStack {
                        Text(metrics.label)
                            .frame(maxWidth: .list.labelWidth,
                                   maxHeight: .list.labelHeight,
                                   alignment: .leading)
                        Text(String(metrics.percentCorrect))
                        Spacer()
                        Text(String(metrics.count))
                    }
                }
            } header: {
                labelSamplesListHeader
            }
        }
    }

    private var labelSamplesListHeader: some View {
        HStack {
            Text(.labelTableHeading)
            Spacer()
            Text(.percentCorrectHeading)
            Spacer()
            Text(.imageCountTableHeading)
        }
        .font(.footnote)
        .foregroundColor(Color(UIColor.secondaryLabel))
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    MetricsSummaryList(metrics: .fakeVegetables)
}

#endif
