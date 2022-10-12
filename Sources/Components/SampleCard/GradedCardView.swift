// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct GradedCardView: View {
    let state: GradedCardViewState
    let imageNamespace: Namespace.ID

    let fetchImage: (UUID) async throws -> UIImage
    let action: () -> Void
    let delete: (LabeledImageID) -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    SampleImageView {
                        try await fetchImage(state.imageID.sampleID)
                    }
                    .aspectRatio(contentMode: .fit)
                    .matchedGeometryEffect(id: state.imageID, in: imageNamespace)

                    predictionBar
                }
                .cornerRadius(.tile.cornerRadius) // rounds top of image
                .background(RoundedRectangle(cornerRadius: .tile.cornerRadius)
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .shadow(color: Color(uiColor: .separator), radius: .tile.shadowRadius, x: 1.0, y: 2.0)
                )
                predictionBarSpacer
            }
        }
        .modifier(DeleteImageContextMenu(action: {
            delete(state.imageID)
        }))
    }

    @ViewBuilder
    private var predictionBar: some View {
        if state.prediction == .blank {
            // There is no prediction bar in this case.

        } else {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                correctOrNotIcon
                label
                Spacer(minLength: 0)
            }
            .padding(4)
            .frame(width: .tile.width)
            .font(.caption)
        }
    }

    @ViewBuilder
    private var predictionBarSpacer: some View {
        if state.prediction == .blank {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemName: "clock")
                    .redacted(reason: .placeholder)
                Text(.redacted)
                    .redacted(reason: .placeholder)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(4)
            .frame(width: .tile.width)
            .font(.caption)
            .opacity(0)
            .accessibilityHidden(true)

        } else {
            // There is no prediction bar spacer in this case.
        }
    }

    @ViewBuilder
    private var correctOrNotIcon: some View {
        switch state.prediction {
        case let .labeled(_, correct):
            if correct {
                Label(.correct, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .labelStyle(.iconOnly)
            } else {
                Label(.incorrect, systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .labelStyle(.iconOnly)
            }

        case .loading:
            Image(systemName: "clock")
                .redacted(reason: .placeholder)
        case .blank:
            EmptyView()
        }
    }

    @ViewBuilder
    private var label: some View {
        switch state.prediction {
        case .loading:
            Text(.redacted)
                .redacted(reason: .placeholder)
                .lineLimit(1)

        case let .labeled(predictedLabel, _):
            Text(predictedLabel)
                .lineLimit(1)
                .foregroundColor(.primary)

        case .blank:
            EmptyView()
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    HStack {
        VStack {
            Text(verbatim: "No model")
            GradedCardPreviewView(
                state: .init(
                    prediction: .blank,
                    imageID: .fakeApple1id
                )
            )
            Spacer()
        }
        VStack {
            Text(verbatim: "Classifying")
            GradedCardPreviewView(
                state: .init(
                    prediction: .loading,
                    imageID: .fakeApple2id
                )
            )
            Spacer()
        }
        ZStack(alignment: .leading) {
            VStack {
                Text(verbatim: "Banana")
                GradedCardPreviewView(
                    state: .init(
                        prediction: .labeled(
                            predictedLabel: "Banana",
                            correct: true),
                        imageID: .fakeApple3id
                    )
                )
                GradedCardPreviewView(
                    state: .init(
                        prediction: .labeled(
                            predictedLabel: "Banana",
                            correct: false
                        ),
                        imageID: .fakeApple4id
                    )
                )
                Spacer()
            }
            HStack(spacing: 0) {
                Rectangle().frame(width: 19).opacity(0)
                Rectangle().frame(width: 1).foregroundColor(.blue)
            }
        }
        VStack {
            Text(verbatim: "Long")
            GradedCardPreviewView(
                state: .init(
                    prediction: .labeled(
                        predictedLabel: "Superlonglabelname",
                        correct: false
                    ),
                    imageID: .fakeApple5id
                )
            )
            Spacer()
        }
    }
}

struct GradedCardPreviewView: View {
    var state: GradedCardViewState

    @Namespace private var imageNamespace

    var body: some View {
        GradedCardView(
            state: state,
            imageNamespace: imageNamespace,
            fetchImage: ImageFetchRepositoryFake.fetchImage,
            action: {
                print("Graded card view action.")
            },
            delete: {
                print("Delete image: '\($0)'.")
            }
        )
        .frame(width: .tile.width)
    }
}

#endif
