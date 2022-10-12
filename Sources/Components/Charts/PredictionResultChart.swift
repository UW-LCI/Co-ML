// Copyright 2026 Apple Inc. All rights reserved.

import Charts
import SwiftUI

struct PredictionResultChart: View {
    let data: [Observation]
    let maxHeight: Float?

    var body: some View {
        Chart {
            chartContent
        }
        .chartYAxis {
            AxisMarks(preset: .extended, values: .automatic) { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.body)
                            .padding(.trailing, 20)
                            .foregroundColor(Color(UIColor.label))
                    }
                }
            }
        }
        .chartXScale(domain: 0...1.2) // increasing the domain so it allows space for the annotation
        .chartXAxis(.hidden)
        .foregroundColor(.blue.opacity(0.7))
        .padding()
        .frame(height: chartMaxHeight) // bars are sized based on frame size
    }

    private var chartMaxHeight: CGFloat {
        guard let maxHeight else {
            return .infinity
        }
        return max(CGFloat(data.count) * .barchart.barMinHeight, CGFloat(maxHeight))
    }

    private var chartContent: some ChartContent {
        // Safe because class labels must be unique
        ForEach(data.stableFirstWithRestSorted, id: \.annotation) { shape in
            BarMark(
                x: .value(.confidence, shape.confidence),
                y: .value(.label, shape.annotation)
            )
            .annotation(position: .trailing, alignment: .leading, spacing: 10) {
                Text(shape.confidence.localizedConfidenceDisplayText).fixedSize()
            }
        }
    }
}

extension Array where Element == Observation {
    // Keeping only the top prediction at the top and everything else in alphabetical order
    var stableFirstWithRestSorted: [Observation] {
        guard let firstElement = self.first else {
            return []
        }
        let restOfArray = self[1...]
        let sortedArray = restOfArray.sorted { $0.annotation < $1.annotation }
        return [firstElement] + sortedArray
    }
}

// MARK: - Previews

#if DEBUG

#Preview(traits: .fixedLayout(width: 400, height: 200)) {
    PredictionResultChart(data: .fake, maxHeight: 200)
}

#Preview("Large", traits: .fixedLayout(width: 400, height: 200)) {
    PredictionResultChart(data: .fakeLargeList, maxHeight: 200)
}

#endif
