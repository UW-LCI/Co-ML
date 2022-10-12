// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct PrepareDataSidebar: View {

    let labelStats: [PrepareDataStatsRow]

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(.prepareTrainingData)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.sidebar.padding)

                sidebarInnerView
            }
            Spacer()
            Divider()
        }
        .frame(width: .sidebar.width)
        .fixedSize(horizontal: true, vertical: false)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var sidebarInnerView: some View {
        if totalSamplesCount > 0 {
            PrepareDataSummaryListView(labelStats: labelStats)
            Spacer()
            prepareDataSampleCountSummaryView
        } else {
            prepareDataHelpTextView
            Spacer()
        }
    }

    private var prepareDataHelpTextView: some View {
        VStack(alignment: .leading) {
            Group {
                Text(.helpTextEditYourLabels)
                Text(.helpTextCollectTrainingData)
                Text(.helpTextAddDiverseImages)
            }
            .foregroundColor(.secondary)
            .padding()
        }
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, .sidebar.padding)
    }

    private var totalSamplesCount: Int {
        labelStats
            .map { $0.count }
            .reduce(0, +)
    }

    private var prepareDataSampleCountSummaryView: some View {
        HStack {
            Spacer()
            Text(.totalTrainingImages(totalSamplesCount))
            .foregroundColor(Color(uiColor: .secondaryLabel))
            .font(.caption)
            .padding(.bottom)
            Spacer()
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    HStack {
        PrepareDataSidebar(labelStats: .fakeVeggies)
        Spacer()
    }
}

#Preview("No Data") {
    HStack {
        PrepareDataSidebar(labelStats: [])
        Spacer()
    }
}

#endif
