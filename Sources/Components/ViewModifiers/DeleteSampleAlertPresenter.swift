// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct DeleteSampleAlertPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let sampleName: String
    let delete: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                .deleteImage(sampleName),
                isPresented: $isPresented,
                actions: {
                    Button(role: .destructive) {
                        delete()
                    } label: {
                        Label(.delete, systemImage: "trash")
                    }
                },
                message: {
                    Text(.thisActionCannotBeUndone)
                }
            )
    }
}

extension View {
    func deleteSampleAlertPresenter(
        isPresented: Binding<Bool>,
        sampleName: String,
        delete: @escaping () -> Void
    ) -> some View {
        modifier(DeleteSampleAlertPresenter(isPresented: isPresented,
                                            sampleName: sampleName,
                                            delete: delete))
    }
}
