// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct MoveSampleAlertPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let sampleName: String
    let source: String
    let destination: String
    let move: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                .moveImage(sampleName),
                isPresented: $isPresented,
                actions: {
                    Button {
                        move()
                    } label: {
                        Text(.moveTo(destination.capitalized))
                    }
                    Button(role: .cancel) {
                        // No-op
                    } label: {
                        Text(.cancel)
                    }
                },
                message: {
                    Text(.thisActionWillMoveThisImageFromTo(source, destination))
                }
            )
    }
}

extension View {
    func moveSampleAlertPresenter(
        isPresented: Binding<Bool>,
        sampleName: String,
        source: String,
        destination: String,
        move: @escaping () -> Void
    ) -> some View {
        modifier(MoveSampleAlertPresenter(isPresented: isPresented,
                                          sampleName: sampleName,
                                          source: source,
                                          destination: destination,
                                          move: move))
    }
}
