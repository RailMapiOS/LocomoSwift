//
//  RealtimeTripDescriptor.swift
//  LocomoSwift
//
//  Realtime descriptor for a trip instance, mirroring `TripDescriptor` from
//  the GTFS-RT protobuf spec.
//

import Foundation

public struct RealtimeTripDescriptor: Hashable, Sendable {

    /// `trip_id` from the GTFS feed. May be `nil` when only `routeID`
    /// (and optionally `directionID`) are used to refer to all trips of a route.
    public let tripID: String?

    /// `route_id` from the GTFS feed.
    public let routeID: String?

    /// Direction of travel as defined in `trips.txt`.
    public let directionID: UInt32?

    /// Initially scheduled start time (e.g. `"08:15:00"`), used for
    /// frequency-based trips or to disambiguate late-running trips.
    public let startTime: String?

    /// Scheduled service date in `YYYYMMDD` format.
    public let startDate: String?

    /// Relationship to the static schedule.
    public let scheduleRelationship: TripScheduleRelationship?

    /// Linkage to a `TripModifications` entity affecting this trip
    /// (experimental in the GTFS-RT spec).
    public let modifiedTrip: ModifiedTripSelector?

    public init(
        tripID: String? = nil,
        routeID: String? = nil,
        directionID: UInt32? = nil,
        startTime: String? = nil,
        startDate: String? = nil,
        scheduleRelationship: TripScheduleRelationship? = nil,
        modifiedTrip: ModifiedTripSelector? = nil
    ) {
        self.tripID = tripID
        self.routeID = routeID
        self.directionID = directionID
        self.startTime = startTime
        self.startDate = startDate
        self.scheduleRelationship = scheduleRelationship
        self.modifiedTrip = modifiedTrip
    }

    /// Selector for a modified trip — references a `TripModifications` entity.
    public struct ModifiedTripSelector: Hashable, Sendable {
        public let modificationsID: String?
        public let affectedTripID: String?
        public let startTime: String?
        public let startDate: String?

        public init(
            modificationsID: String? = nil,
            affectedTripID: String? = nil,
            startTime: String? = nil,
            startDate: String? = nil
        ) {
            self.modificationsID = modificationsID
            self.affectedTripID = affectedTripID
            self.startTime = startTime
            self.startDate = startDate
        }
    }
}
