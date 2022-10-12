// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct EvaluationMetricNoModelSidebar: View {
    let labels: [LabelWithSampleCount]

    var body: some View {
        VStack(alignment: .leading) {
            testResultsUnavailableHeading
            trainModelFirstParagraph
            labelSamplesTable
            Spacer()
        }
    }

    private var testResultsUnavailableHeading: some View {
        Text(.modelTestingIsUnavailable)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.sidebar.padding)
    }

    private var trainModelFirstParagraph: some View {
        VStack {
            Text(.trainAModelFirstEtc)
                .foregroundColor(.secondary)
                .padding()
        }
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, .sidebar.padding)
    }

    @ViewBuilder
    private var labelSamplesTable: some View {
        if !labels.isEmpty {
            List {
                Section {
                    ForEach(labels) { label in
                        HStack {
                            Text(label.label.labelString)
                            Spacer()
                            Text(String(label.sampleCount))
                        }
                    }
                } header: {
                    labelSamplesTableHeader
                }
            }
        }
    }

    private var labelSamplesTableHeader: some View {
        HStack {
            Text(.labelTableHeading)
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
    EvaluationMetricNoModelSidebar(
        labels: [
            LabelWithSampleCount(label: .fakeAppleLabel, sampleCount: 123),
            LabelWithSampleCount(label: .fakeBananaLabel, sampleCount: 456),
            LabelWithSampleCount(label: .fakeCarrotLabel, sampleCount: 789),
        ]
    )
}

#endif
