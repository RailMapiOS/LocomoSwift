//
//  Feed+Realtime.swift
//  LocomoSwift
//

import Foundation
import LocomoSwiftGTFS

extension Feed {

    /// Creates a realtime manager for this feed, with the default decoder
    /// and `URLSession.shared` networking.
    public func createRealtimeManager() -> RealtimeManager {
        RealtimeManager()
    }

    /// Applies realtime updates to the feed. Currently a stub — the GTFS
    /// static models don't yet carry realtime delay/cancellation state, so
    /// the input data is accepted and silently dropped.
    ///
    /// Use ``RealtimeManager`` directly to query trip updates, vehicle
    /// positions, and service alerts in the meantime.
    public mutating func applyRealtimeUpdates(
        tripUpdates: [RealtimeTripUpdate] = [],
        vehiclePositions: [RealtimeVehiclePosition] = [],
        serviceAlerts: [RealtimeServiceAlert] = []
    ) {
        _ = tripUpdates
        _ = vehiclePositions
        _ = serviceAlerts
        // TODO: store delays on `StopTime`, cancellations on `Trip`, and
        // alerts on a new `Feed.alerts` collection.
    }

    /// Returns the realtime status of a trip — currently a stub returning
    /// a not-delayed/not-cancelled placeholder.
    public func realtimeStatus(for tripID: String) -> TripRealtimeStatus? {
        guard trips?.trips.contains(where: { $0.tripID == tripID }) == true else {
            return nil
        }
        // TODO: derive from applied realtime updates once stored.
        return TripRealtimeStatus(
            tripID: tripID,
            isDelayed: false,
            averageDelay: 0,
            isCancelled: false,
            lastUpdate: Date()
        )
    }
}

// MARK: - TripRealtimeStatus

public struct TripRealtimeStatus: Hashable, Sendable {
    public let tripID: String
    public let isDelayed: Bool
    public let averageDelay: TimeInterval
    public let isCancelled: Bool
    public let lastUpdate: Date

    public init(
        tripID: String,
        isDelayed: Bool,
        averageDelay: TimeInterval,
        isCancelled: Bool,
        lastUpdate: Date
    ) {
        self.tripID = tripID
        self.isDelayed = isDelayed
        self.averageDelay = averageDelay
        self.isCancelled = isCancelled
        self.lastUpdate = lastUpdate
    }
}
