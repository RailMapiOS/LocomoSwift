//
//  RealtimeFeed.swift
//  LocomoSwift
//
//  Top-level container mirroring a `FeedMessage` — header plus the
//  parsed entities of every kind.
//

import Foundation

public struct RealtimeFeed: Sendable {

    public let header: RealtimeFeedHeader

    /// Trip updates contained in the feed.
    public let tripUpdates: [RealtimeTripUpdate]

    /// Vehicle positions contained in the feed.
    public let vehiclePositions: [RealtimeVehiclePosition]

    /// Service alerts contained in the feed.
    public let serviceAlerts: [RealtimeServiceAlert]

    /// Realtime-only shapes (encoded polylines for detours, experimental).
    public let shapes: [RealtimeShape]

    /// Identifiers of `FeedEntity` records that were marked `isDeleted = true`.
    /// Only meaningful when ``RealtimeFeedHeader/incrementality`` is `.differential`.
    public let deletedEntityIDs: [String]

    public init(
        header: RealtimeFeedHeader,
        tripUpdates: [RealtimeTripUpdate] = [],
        vehiclePositions: [RealtimeVehiclePosition] = [],
        serviceAlerts: [RealtimeServiceAlert] = [],
        shapes: [RealtimeShape] = [],
        deletedEntityIDs: [String] = []
    ) {
        self.header = header
        self.tripUpdates = tripUpdates
        self.vehiclePositions = vehiclePositions
        self.serviceAlerts = serviceAlerts
        self.shapes = shapes
        self.deletedEntityIDs = deletedEntityIDs
    }
}
