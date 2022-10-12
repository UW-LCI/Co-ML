// Copyright 2026 Apple Inc. All rights reserved.

import os.log
import SwiftUI

/// A view configured with a labeled image, which may fetch the underlying UIImage asynchronously.
struct SampleImageView: View {
    let fetchImage: () async throws -> UIImage

    @State private var state = SampleImageViewState.loading

    var body: some View {
        InnerSampleImageView(state: state)
            .task {
                do {
                    guard case .loading = state else {
                        return
                    }
                    let image = try await fetchImage()
                    state = .loaded(image: image)
                } catch {
                    os_log(.error, "Failed to async load an image: \(error)")
                    state = .failed
                }
            }
    }
}

/// Enum representing the 3 possible states of the image view.
private enum SampleImageViewState {
    case loading
    case loaded(image: UIImage)
    case failed
}

/// Statically-configured inner view, with no business logic or dependencies.
private struct InnerSampleImageView: View {
    let state: SampleImageViewState

    var body: some View {
        Group {
            switch state {
            case .loading:
                Rectangle()
                    .foregroundColor(Color(.secondarySystemBackground))

            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .accessibilityIgnoresInvertColors()

            case .failed:
                Rectangle()
                    .foregroundColor(Color(.secondarySystemBackground))
                    .overlay {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.secondary)
                    }
            }
        }
        .accessibilityLabel(.labeledImage)
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    HStack {
        VStack {
            Text(verbatim: "Loading")
            InnerSampleImageView(state: .loading)
                .frame(width: 100, height: 100)
            Spacer()
        }
        Divider()

        VStack {
            Text(verbatim: "Failed")
            InnerSampleImageView(state: .failed)
                .frame(width: 100, height: 100)
            Spacer()
        }

        Divider()

        VStack {
            Text(verbatim: "Loaded")
            InnerSampleImageView(
                state: .loaded(image: UIImage(systemName: "globe.americas")!)
            )
            .frame(width: 100, height: 100)
            Spacer()
        }
    }
}

#endif
