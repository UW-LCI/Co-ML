// Copyright 2026 Apple Inc. All rights reserved.


import SwiftUI

/// Helper to test views that take bindings
/// correctly update when they change the binding
/// Call with a view like this:
///
///     PreviewHelperView(initialValue) { $value in
///         MyView(value)
struct PreviewHelperView<T, V: View>: View {
    @State var state: T {
        didSet {
            print("Updating state to \(state)")
        }
    }

    @ViewBuilder let view: (Binding<T>) -> V
    var body: some View {
        view($state)
    }
}

/// Helper to test views that take ObservableObjects
/// Correctly update when @Published values are updated in the model
struct PreviewHelperStateObjectView<T: ObservableObject, V: View>: View {
    @StateObject var model: T

    let view: (T) -> V
    var body: some View {
        view(model)
    }
}
