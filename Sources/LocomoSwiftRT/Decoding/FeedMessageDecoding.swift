//
//  FeedMessageDecoding.swift
//  LocomoSwift
//
//  Abstraction over GTFS-RT byte decoding so consumers can plug in custom
//  decoders (compression, alternative formats, fixtures…) without
//  touching `RealtimeManager`.
//

import Foundation

public protocol FeedMessageDecoding: Sendable {
    /// Decode raw GTFS-RT bytes into a fully-mapped ``RealtimeFeed``.
    /// Implementations must throw a descriptive error on malformed input.
    func decode(_ data: Data) throws -> RealtimeFeed
}
