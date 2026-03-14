//
//  RealtimeTripUpdate.swift
//  LocomoSwift
//
//  Created by LocomoSwift on 2024.
//

import Foundation

/// Real-time update on the progress of a vehicle along a trip.
public struct RTTripUpdate: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// The trip this update applies to.
    public let trip: RTTripDescriptor
    /// Additional information on the vehicle serving this trip.
    public let vehicle: RTVehicleDescriptor?
    /// Updates to StopTimes for the trip (both future and, in some cases, past).
    public let stopTimeUpdates: [StopTimeUpdate]
    /// Moment at which the vehicle's real-time progress was measured.
    public let timestamp: Date?
    /// The current schedule deviation for the trip. Only provided when the trip-level delay is known.
    public let delay: Int?

    public init(id: UUID = UUID(), trip: RTTripDescriptor, vehicle: RTVehicleDescriptor? = nil,
                stopTimeUpdates: [StopTimeUpdate] = [], timestamp: Date? = nil, delay: Int? = nil) {
        self.id = id
        self.trip = trip
        self.vehicle = vehicle
        self.stopTimeUpdates = stopTimeUpdates
        self.timestamp = timestamp
        self.delay = delay
    }

    // MARK: - StopTimeUpdate

    /// Realtime update for arrival/departure events for a given stop on a trip.
    public struct StopTimeUpdate: Hashable, Sendable {
        /// The stop sequence (must be the same as in the GTFS stop_times.txt).
        public let stopSequence: UInt?
        /// The stop_id from the GTFS feed.
        public let stopID: LSID?
        /// Updated arrival information.
        public let arrival: StopTimeEvent?
        /// Updated departure information.
        public let departure: StopTimeEvent?
        /// The relationship between this StopTime and the static schedule.
        public let scheduleRelationship: ScheduleRelationship
        /// Realtime occupancy status at departure.
        public let departureOccupancyStatus: RTOccupancyStatus?

        public init(stopSequence: UInt? = nil, stopID: LSID? = nil,
                    arrival: StopTimeEvent? = nil, departure: StopTimeEvent? = nil,
                    scheduleRelationship: ScheduleRelationship = .scheduled,
                    departureOccupancyStatus: RTOccupancyStatus? = nil) {
            self.stopSequence = stopSequence
            self.stopID = stopID
            self.arrival = arrival
            self.departure = departure
            self.scheduleRelationship = scheduleRelationship
            self.departureOccupancyStatus = departureOccupancyStatus
        }
    }

    // MARK: - StopTimeEvent

    /// Timing information for a single predicted event (arrival or departure).
    public struct StopTimeEvent: Hashable, Sendable {
        /// Delay (in seconds) relative to the scheduled time. Positive = late, negative = early.
        public let delay: Int?
        /// Absolute time for the event.
        public let time: Date?
        /// Uncertainty of the prediction in seconds. 0 means the prediction is exact.
        public let uncertainty: Int?

        public init(delay: Int? = nil, time: Date? = nil, uncertainty: Int? = nil) {
            self.delay = delay
            self.time = time
            self.uncertainty = uncertainty
        }
    }

    // MARK: - ScheduleRelationship

    /// The relation between a stop time update and the static schedule.
    public enum ScheduleRelationship: Int, Sendable {
        /// The vehicle is proceeding in accordance with its static schedule.
        case scheduled = 0
        /// The stop is skipped.
        case skipped = 1
        /// No data is given for this stop.
        case noData = 2
        /// The vehicle is serving a stop that is not in the static schedule.
        case unscheduled = 3
    }
}

// MARK: - Internal Protobuf Conversion

extension RTTripUpdate {
    init(from proto: TransitRealtime_TripUpdate) {
        self.id = UUID()
        self.trip = RTTripDescriptor(from: proto.trip)
        self.vehicle = proto.hasVehicle ? RTVehicleDescriptor(from: proto.vehicle) : nil
        self.stopTimeUpdates = proto.stopTimeUpdate.map { StopTimeUpdate(from: $0) }
        self.timestamp = proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : nil
        self.delay = proto.hasDelay ? Int(proto.delay) : nil
    }
}

extension RTTripUpdate.StopTimeUpdate {
    init(from proto: TransitRealtime_TripUpdate.StopTimeUpdate) {
        self.stopSequence = proto.hasStopSequence ? UInt(proto.stopSequence) : nil
        self.stopID = proto.hasStopID ? proto.stopID : nil
        self.arrival = proto.hasArrival ? RTTripUpdate.StopTimeEvent(from: proto.arrival) : nil
        self.departure = proto.hasDeparture ? RTTripUpdate.StopTimeEvent(from: proto.departure) : nil
        self.scheduleRelationship = RTTripUpdate.ScheduleRelationship(rawValue: proto.scheduleRelationship.rawValue) ?? .scheduled
        self.departureOccupancyStatus = proto.hasDepartureOccupancyStatus
            ? RTOccupancyStatus(rawValue: proto.departureOccupancyStatus.rawValue)
            : nil
    }
}

extension RTTripUpdate.StopTimeEvent {
    init(from proto: TransitRealtime_TripUpdate.StopTimeEvent) {
        self.delay = proto.hasDelay ? Int(proto.delay) : nil
        self.time = proto.hasTime ? Date(timeIntervalSince1970: TimeInterval(proto.time)) : nil
        self.uncertainty = proto.hasUncertainty ? Int(proto.uncertainty) : nil
    }
}
