// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

struct ProjectShareButton<T>: View {
    let shareState: ShareState<T>
    let online: Bool
    let shareButtonPressed: () -> Void

    var body: some View {
        Button {
            shareButtonPressed()
        } label: {
            switch shareState {
            case .notYetShared, .shared, .notSignedIn:
                Label(buttonTitle, systemImage: icon)
            case .pending:
                ProgressView()
            }
        }
        .disabled(shareState.isPending)
        .accessibilityHint(Text(hint))
        .accessibilityInputLabels([
            String(localized: .shareProject),
            String(localized: .share),
            String(localized: .sharing),
            String(localized: .addPeople)
        ])
    }

    // MARK: - Private

    private var buttonTitle: LocalizedStringResource {
        switch shareState {
        case .notYetShared:
            // This is the name even when *not online*.
            return .shareProject

        case .shared(_, isOwner: true):
            return .addPeopleToProject

        case .shared(_, isOwner: false):
            return .showPeopleInProject

        case .notSignedIn:
            return .sharingNotSignedIntoICloud

        case .pending:
            assertionFailure("Button should not be displayed for share state pending.")
            return ""
        }
    }

    private var hint: String {
        if !online {
            String(localized: .sharingIsNotAvailableWhileOffLine)
        } else {
            ""
        }
    }

    private var icon: String {
        switch shareState {
        case .notYetShared:
            if online {
                return "square.and.arrow.up"
            } else {
                return "square.and.arrow.up.trianglebadge.exclamationmark"
            }
        case .shared(_, isOwner: true):
            if online {
                return "person.crop.circle.badge.plus"
            } else {
                return "person.crop.circle.badge.exclamationmark"
            }
        case .shared(_, isOwner: false):
            if online {
                return "person.crop.circle.badge.questionmark"
            } else {
                return "person.crop.circle.badge.exclamationmark"
            }
        case .notSignedIn:
            return "person.crop.circle.badge.exclamationmark"

        case .pending:
            // Note this will be overlaid by a progress circle
            return "person.crop.circle"
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview {
    NavigationStack {
        VStack(spacing: 40) {
            GroupBox {
                ForEach(Array([FakeShareState].fakeStates.enumerated()), id: \.offset) { (offset, state) in
                    ProjectShareButton(shareState: state, online: true, shareButtonPressed: {})
                }
            } label: {
                Text(verbatim: "Online")
            }

            GroupBox {
                ForEach(Array([FakeShareState].fakeStates.enumerated()), id: \.offset) { (offset, state) in
                    ProjectShareButton(shareState: state, online: false, shareButtonPressed: {})
                }
            } label: {
                Text(verbatim: "Offline")
            }

            GroupBox {
                PreviewHelperView(state: false) { $pending in
                    HStack {
                        ForEach(Array([FakeShareState].fakeStates.enumerated()), id: \.offset) { (offset, state) in
                            let newState: FakeShareState = pending
                            ? .pending : state

                            ProjectShareButton(shareState: newState, online: false, shareButtonPressed: {})
                                .labelStyle(.iconOnly)
                        }
                    }
                    Divider()
                    Toggle(isOn: $pending) {
                        Text(verbatim: "Pending")
                    }.frame(width: 200)
                }
            } label: {
                Text(verbatim: "Transition")
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Text(verbatim: "online:")

                ForEach(Array([FakeShareState].fakeStates.enumerated()), id: \.offset) { (offset, state) in

                    ProjectShareButton(shareState: state, online: true, shareButtonPressed: {})
                        .labelStyle(.iconOnly)
                }
            }

            ToolbarItemGroup {
                Text(verbatim: "offline:")

                ForEach(Array([FakeShareState].fakeStates.enumerated()), id: \.offset) { (offset, state) in

                    ProjectShareButton(shareState: state, online: false, shareButtonPressed: {})
                        .labelStyle(.iconOnly)

                }
            }
        }
    }
    /// Borderless style lets toolbars have color
    .buttonStyle(.borderless)
}

typealias FakeShareState = ShareState<Void>

extension [FakeShareState] {
    static let fakeStates: Self = [
        .notYetShared,
        .pending,
        .shared((), isOwner: true),
        .shared((), isOwner: false),
        .notSignedIn
    ]
}

#endif
