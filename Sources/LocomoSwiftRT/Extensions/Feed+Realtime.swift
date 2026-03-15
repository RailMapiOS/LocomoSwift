//
//  Feed+Realtime.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation
import LocomoSwiftGTFS

// MARK: - Feed Realtime Extensions

extension Feed {

    /// Creates a realtime manager for this feed.
    public func createRealtimeManager() -> RealtimeManager {
        return RealtimeManager()
    }

    /// Applies realtime updates to the feed.
    public mutating func applyRealtimeUpdates(
        tripUpdates: [RealtimeTripUpdate] = [],
        vehiclePositions: [RealtimeVehiclePosition] = [],
        serviceAlerts: [RealtimeServiceAlert] = []
    ) {
        for tripUpdate in tripUpdates {
            applyTripUpdate(tripUpdate)
        }

        for vehiclePosition in vehiclePositions {
            applyVehiclePosition(vehiclePosition)
        }

        // TODO: Implement alert storage
    }

    /// Returns the realtime status of a trip.
    public func realtimeStatus(for tripID: String) -> TripRealtimeStatus? {
        guard let _ = trips?.trips.first(where: { $0.tripID == tripID }) else {
            return nil
        }

        // TODO: Implement realtime status logic
        return TripRealtimeStatus(
            tripID: tripID,
            isDelayed: false,
            averageDelay: 0,
            isCancelled: false,
            lastUpdate: Date()
        )
    }

    // MARK: - Private Methods

    private mutating func applyTripUpdate(_ tripUpdate: RealtimeTripUpdate) {
        guard let _ = trips?.trips.firstIndex(where: { $0.tripID == tripUpdate.tripID }) else {
            return
        }

        if tripUpdate.scheduleRelationship == .cancelled {
            // TODO: Add isCancelled property to Trip
            return
        }

        for stopTimeUpdate in tripUpdate.stopTimeUpdates {
            applyStopTimeUpdate(stopTimeUpdate, for: tripUpdate.tripID)
        }
    }

    private mutating func applyStopTimeUpdate(_ update: RealtimeStopTimeUpdate, for tripID: String) {
        guard let _ = stopTimes?.stopTimes.firstIndex(where: {
            $0.tripID == tripID && $0.stopID == update.stopID
        }) else {
            return
        }

        // TODO: Add delay properties to StopTime
    }

    private mutating func applyVehiclePosition(_ position: RealtimeVehiclePosition) {
        // TODO: Implement vehicle position application
    }
}

// MARK: - TripRealtimeStatus

public struct TripRealtimeStatus {
    public let tripID: String
    public let isDelayed: Bool
    public let averageDelay: TimeInterval
    public let isCancelled: Bool
    public let lastUpdate: Date
}
