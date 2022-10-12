// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ExportProjectSummaryView: View {
    let labelNames: [String]

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(.labels)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Divider()

                ForEach(labelNames, id: \.self) {
                    Text($0)
                        .padding(.bottom, .tile.spacing)
                }
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: 300)
        .overlay(Divider(), alignment: .leading)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    ExportProjectSummaryView(labelNames: ["Hat", "Bag", "Socks"])
}

#endif
