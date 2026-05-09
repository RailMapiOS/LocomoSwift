//
//  RealtimeShape.swift
//  LocomoSwift
//
//  A realtime-only shape (encoded polyline) used to describe a path that
//  isn't part of static GTFS — typically a detour. Experimental in the spec.
//

import Foundation

public struct RealtimeShape: Hashable, Sendable, Identifiable {

    /// Identifier of the shape. Must differ from any `shape_id` in the
    /// static GTFS feed.
    public let id: String

    /// Encoded polyline (Google polyline algorithm) representing the path
    /// taken by the vehicle. Decode with the polyline algorithm of your
    /// choice — LocomoSwift doesn't include a decoder.
    public let encodedPolyline: String

    public init(id: String, encodedPolyline: String) {
        self.id = id
        self.encodedPolyline = encodedPolyline
    }
}
