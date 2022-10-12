// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// View extension facilitating concise iCloud alert presentation.
extension View {
    func iCloudAlertPresenter() -> some View {
        modifier(IcloudAlertPresenter())
    }
}

/// View modifier that waits for `cloudKitExportErrorCodes` and when encountered, presents an error to the user.
struct IcloudAlertPresenter: ViewModifier {

    @State private var showingCloudKitAlert = false
    @State private var lastCloudKitErrorCode = 0
    @State private var ignoreFutureCloudKitErrors = false

    func body(content: Content) -> some View {
        content
            .modifier(IcloudAlert(
                isPresented: $showingCloudKitAlert,
                lastCloudKitErrorCode: $lastCloudKitErrorCode,
                dismiss: {
                    showingCloudKitAlert = false
                    ignoreFutureCloudKitErrors = true
                },
                dontTellMeAgain: {
                    showingCloudKitAlert = false
                }
            ))
            .task {
                for await errorCode in NotificationCenter.default.cloudKitExportErrorCodes() {
                    if ignoreFutureCloudKitErrors {
                        break
                    }
                    lastCloudKitErrorCode = errorCode
                    showingCloudKitAlert = true
                }
            }
    }
}

/// View modifier handling static presentation of an iCloud alert, and delegating button press handling upwards.
private struct IcloudAlert: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var lastCloudKitErrorCode: Int
    let dismiss: () -> Void
    let dontTellMeAgain: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                .iCloudSharingFailed,
                isPresented: $isPresented,
                actions: {
                    Button {
                        dontTellMeAgain()
                    } label: {
                        Text(.dontTellMeAgain)
                    }

                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text(.ok)
                    }

                }, message: {
                    Text(.someOfTheChangesYouMadeMightNotBeVisibleEtc(lastCloudKitErrorCode))
                }
            )
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Icloud alert") {
    Text(verbatim: "Hello, world!")
        .modifier(
            IcloudAlert(
                isPresented: .constant(true),
                lastCloudKitErrorCode: .constant(2),
                dismiss: {
                    print("dismiss")
                },
                dontTellMeAgain: {
                    print("don't tell me again")
                }
            )
        )
}

#endif
