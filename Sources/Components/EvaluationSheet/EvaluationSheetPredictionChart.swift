// Copyright 2026 Apple Inc. All rights reserved.

import Charts
import SwiftUI

struct EvaluationSheetPredictionChart: View {
    private let observations: [StyledObservation]

    init(observations: [Observation]) {
        guard let topObservation = observations.first else {
            self.observations = []
            return
        }
        var styledObservations = [
            StyledObservation(annotation: topObservation.annotation,
                              confidence: topObservation.confidence,
                              textColor: .white,
                              isTop: true)
        ]
        let otherObservations = observations[1...].map {
            StyledObservation(annotation: $0.annotation,
                              confidence: $0.confidence,
                              textColor: .primary,
                              isTop: false)
        }
        styledObservations.append(contentsOf: otherObservations)
        self.observations = styledObservations
    }

    var body: some View {
        Chart {
            ForEach(observations) { observation in
                BarMark(
                    x: .value(.confidence, observation.confidence),
                    y: .value(.label, observation.annotation)
                )
                .foregroundStyle(by: .value(String(localized: .barColor), observation.isTopPlottable))
                .annotation(position: .overlay, alignment: .leading, spacing: 10) {
                    Text(observation.confidence.localizedConfidenceDisplayText)
                        .fixedSize()
                        .foregroundColor(observation.textColor)
                }
            }
        }
        .chartForegroundStyleScale([
            0: Color.accentColor.opacity(0.2),
            1: Color.accentColor
        ])
        .chartYAxis {
            AxisMarks(preset: .extended) { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.body)
                            .padding(.trailing)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .chartXAxis(.hidden)
    }
}

private struct StyledObservation: Identifiable {
    let annotation: String
    let confidence: Double
    let textColor: Color

    let isTop: Bool

    /// Whether the styled observation is the top observation, in a plottable manner.
    var isTopPlottable: Int {
        isTop ? 1 : 0
    }

    // MARK: - Identifiable

    var id: String {
        annotation
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    VStack {
        EvaluationSheetPredictionChart(
            observations: .fake
        )
        .frame(height: 400)

        Spacer()
    }
    .padding()
}

#endif
