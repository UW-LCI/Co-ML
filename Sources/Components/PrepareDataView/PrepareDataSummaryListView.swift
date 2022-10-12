// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct PrepareDataSummaryListView: View {
    let labelStats: [PrepareDataStatsRow]

    var body: some View {
        List {
            Section {
                ForEach(labelStats) { labelInfo in
                    HStack {
                        Text(labelInfo.label)
                        Spacer()
                        Text(labelInfo.count.description)
                    }
                }
            } header: {
                labelListHeader
            }
        }
    }

    private var labelListHeader: some View {
        HStack {
            Text(.labelTableHeading)
            Spacer()
            Text(.imageCountTableHeading)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    HStack {
        PrepareDataSummaryListView(labelStats: .fakeVeggies)
            .frame(width: .sidebar.width)
        Spacer()
    }
}

#endif
