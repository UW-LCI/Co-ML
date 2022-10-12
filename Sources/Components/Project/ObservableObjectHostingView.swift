// Copyright 2026 Apple Inc. All rights reserved.

import SwiftUI

/// View to host an observableObject
struct ObservableObjectHostingView<Model: ObservableObject, Content: View>: View {

    @ObservedObject var model: Model
    @ViewBuilder var content: (Model) -> Content

    var body: some View {
        content(model)
    }
}
