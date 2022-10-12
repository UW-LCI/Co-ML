// Copyright 2026 Apple Inc. All rights reserved.

/// A Subject which produces a single stream of values you can send to
actor Subject<T>: Sendable {

    typealias Stream = AsyncStream<T>

    let stream: Stream
    var continuation: Stream.Continuation

    init() {
        (stream, continuation) = makeStreamAndContinuation(for: T.self)
    }

    deinit {
        continuation.finish()
    }

    func send(_ value: T) {
        continuation.yield(value)
    }
}

/// Copied from swift.org discussion https://forums.swift.org/t/pitch-convenience-async-throwing-stream-makestream-methods
private func makeStreamAndContinuation<T>(for _: T.Type) -> (AsyncStream<T>, AsyncStream<T>.Continuation) {
    var continuation: AsyncStream<T>.Continuation?
    let asyncStream = AsyncStream<T> {
        continuation = $0
    }
    return (asyncStream, continuation!)
}
