// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI
import os.log

typealias CameraPredictionOverlayState = [Observation]

struct CameraPredictionOverlay: View {
    @ObservedObject var viewModel: ClassificationCameraViewModel

    var body: some View {
        VStack {
            if viewModel.isModelOutOfDate {
                ModelOutOfDateBar() // N.B. this bar cannot facilitate navigation.
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .backgroundStyle(.ultraThinMaterial)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Spacer()
            PredictionView(observations: viewModel.liveStreamedObservations)
        }
    }
}

private struct PredictionView: View {
    let observations: [Observation]
    @State private var showAllPredictions = false

    private let outerPadding = 12.0

    var body: some View {
        if let topObservation = observations.first {
            VStack {
                Text(.modelPredictionOverlayHeader)
                    .padding(.top, outerPadding)
                    .padding(.bottom, 6)
                    .foregroundColor(.secondary)
                    .font(.subheadline)

                HStack {
                    Text(topObservation.annotation)
                        .padding(.leading, outerPadding)
                    if !showAllPredictions {
                        Spacer()
                        Text(topObservation.confidence.localizedConfidenceDisplayText)
                            .padding(.trailing, outerPadding)
                            .transition(.move(edge: .trailing))
                    }
                }
                .font(.title)
                .fontWeight(.bold)

                Divider()
                    .padding(.horizontal, outerPadding)

                if showAllPredictions {
                    VStack(alignment: .leading) {
                        PredictionResultChart(data: observations, maxHeight: Float(UIScreen.main.bounds.width) / 7.0)
                        Text(.resultsAreBasedOnYourMostRecentlyTrainedModel)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .padding(.leading, outerPadding)
                        Divider()
                            .padding(.horizontal, outerPadding)
                    }
                }

                Button {
                    withAnimation {
                        showAllPredictions.toggle()
                    }
                } label: {
                    Label {
                        Text(showAllPredictions ? .hideDetails : .showDetails)
                    } icon: {
                        Image(systemName: showAllPredictions ? "chevron.down" : "chevron.up")
                    }
                }
                .padding(.bottom, outerPadding)
            }
            .frame(maxWidth: UIScreen.main.bounds.width / 2.5)
            .background(in: RoundedRectangle(cornerRadius: 10))
            .backgroundStyle(.ultraThinMaterial)
            .clipped()
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    PredictionsPreviewView()
}

/// Allows the transition animation to be demonstrated.
private struct PredictionsPreviewView: View {

    @State private var observations: [Observation] = .fakeDiverseObservations
    @State private var showAll100 = false

    var body: some View {
        VStack {
            PredictionView(observations: observations)
            Button {
                withAnimation(.easeOut(duration: 1.5)) {
                    observations = showAll100 ? .fakeDiverseObservations : .fakeObservationsAll100
                    showAll100.toggle()
                }
            } label: {
                Text(verbatim: "Animate bars")
            }

            Spacer()
        }
    }
}

private extension [Observation] {
    static var fakeDiverseObservations: Self {
        [
            Observation(annotation: "Apple", confidence: 0.8888),
            Observation(annotation: "Strawberry", confidence: 0.75),
            Observation(annotation: "Orange", confidence: 0.49),
            Observation(annotation: "Banana", confidence: 0.03),
        ]
    }

    static var fakeObservationsAll100: Self {
        [
            Observation(annotation: "Apple", confidence: 1.0),
            Observation(annotation: "Strawberry", confidence: 1.0),
            Observation(annotation: "Orange", confidence: 1.0),
            Observation(annotation: "Banana", confidence: 1.0),
        ]
    }
}

#endif
