//
//  RealtimeShared.swift
//  LocomoSwift
//
//  Created by LocomoSwift on 2024.
//

import Foundation
import CoreLocation

// MARK: - TripDescriptor

/// Identifies a trip instance in a GTFS Realtime feed.
public struct RTTripDescriptor: Hashable, Sendable {
    /// The trip_id from the GTFS feed.
    public let tripID: LSID?
    /// The route_id from the GTFS feed.
    public let routeID: LSID?
    /// The direction_id from the GTFS feed.
    public let directionID: UInt?
    /// The initially scheduled start time of this trip instance.
    public let startTime: String?
    /// The start date of this trip instance in YYYYMMDD format.
    public let startDate: String?
    /// The relationship between this trip and the static schedule.
    public let scheduleRelationship: RTScheduleRelationship?

    public init(tripID: LSID? = nil, routeID: LSID? = nil, directionID: UInt? = nil,
                startTime: String? = nil, startDate: String? = nil,
                scheduleRelationship: RTScheduleRelationship? = nil) {
        self.tripID = tripID
        self.routeID = routeID
        self.directionID = directionID
        self.startTime = startTime
        self.startDate = startDate
        self.scheduleRelationship = scheduleRelationship
    }

    /// The relationship between a trip and the static schedule.
    public enum RTScheduleRelationship: Int, Sendable {
        case scheduled = 0
        case added = 1
        case unscheduled = 2
        case canceled = 3
        case replacement = 5
        case duplicated = 6
        case deleted = 7
        case new = 8
    }
}

// MARK: - VehicleDescriptor

/// Identification information for the vehicle performing the trip.
public struct RTVehicleDescriptor: Hashable, Sendable {
    /// Internal system identification of the vehicle.
    public let id: LSID?
    /// User visible label (e.g., the name of a train).
    public let label: String?
    /// The license plate of the vehicle.
    public let licensePlate: String?
    /// Wheelchair accessibility of the vehicle.
    public let wheelchairAccessible: RTWheelchairAccessible?

    public init(id: LSID? = nil, label: String? = nil, licensePlate: String? = nil,
                wheelchairAccessible: RTWheelchairAccessible? = nil) {
        self.id = id
        self.label = label
        self.licensePlate = licensePlate
        self.wheelchairAccessible = wheelchairAccessible
    }

    public enum RTWheelchairAccessible: Int, Sendable {
        case noValue = 0
        case unknown = 1
        case wheelchairAccessible = 2
        case wheelchairInaccessible = 3
    }
}

// MARK: - Position

/// A geographic position of a vehicle.
public struct RTPosition: Hashable, Sendable {
    /// Degrees North, in the WGS-84 coordinate system.
    public let latitude: CLLocationDegrees
    /// Degrees East, in the WGS-84 coordinate system.
    public let longitude: CLLocationDegrees
    /// Bearing, in degrees, clockwise from True North.
    public let bearing: Float?
    /// Odometer value, in meters.
    public let odometer: Double?
    /// Momentary speed measured by the vehicle, in meters per second.
    public let speed: Float?

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                bearing: Float? = nil, odometer: Double? = nil, speed: Float? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.bearing = bearing
        self.odometer = odometer
        self.speed = speed
    }
}

// MARK: - TranslatedString

/// An internationalized message containing per-language versions of a snippet of text.
public struct RTTranslatedString: Hashable, Sendable {
    public let translations: [Translation]

    public init(translations: [Translation]) {
        self.translations = translations
    }

    /// A single translation with a language tag.
    public struct Translation: Hashable, Sendable {
        public let text: String
        public let language: String?

        public init(text: String, language: String? = nil) {
            self.text = text
            self.language = language
        }
    }

    /// Returns the text for a preferred language, or the first available translation.
    public func text(forLanguage language: String? = nil) -> String? {
        if let language = language {
            if let match = translations.first(where: { $0.language == language }) {
                return match.text
            }
        }
        // Fallback: look for no-language entry, then first entry
        return translations.first(where: { $0.language == nil || $0.language?.isEmpty == true })?.text
            ?? translations.first?.text
    }
}

// MARK: - TimeRange

/// A time interval with optional start and end.
public struct RTTimeRange: Hashable, Sendable {
    /// Start time, in POSIX time (i.e., seconds since January 1st 1970 00:00:00 UTC).
    public let start: Date?
    /// End time, in POSIX time.
    public let end: Date?

    public init(start: Date? = nil, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    /// Whether the given date falls within this time range.
    public func contains(_ date: Date) -> Bool {
        if let start = start, date < start { return false }
        if let end = end, date > end { return false }
        return true
    }
}

// MARK: - EntitySelector

/// A selector for an entity in a GTFS feed, used by alerts.
public struct RTEntitySelector: Hashable, Sendable {
    public let agencyID: LSID?
    public let routeID: LSID?
    public let routeType: Int?
    public let trip: RTTripDescriptor?
    public let stopID: LSID?
    public let directionID: UInt?

    public init(agencyID: LSID? = nil, routeID: LSID? = nil, routeType: Int? = nil,
                trip: RTTripDescriptor? = nil, stopID: LSID? = nil, directionID: UInt? = nil) {
        self.agencyID = agencyID
        self.routeID = routeID
        self.routeType = routeType
        self.trip = trip
        self.stopID = stopID
        self.directionID = directionID
    }
}

// MARK: - Vehicle Enums

/// The status of the vehicle with respect to the current stop.
public enum RTVehicleStopStatus: Int, Sendable {
    /// The vehicle is just about to arrive at the stop.
    case incomingAt = 0
    /// The vehicle is standing at the stop.
    case stoppedAt = 1
    /// The vehicle has departed and is in transit to the next stop.
    case inTransitTo = 2
}

/// Congestion level that is affecting this vehicle.
public enum RTCongestionLevel: Int, Sendable {
    case unknownCongestionLevel = 0
    case runningSmoothly = 1
    case stopAndGo = 2
    case congestion = 3
    case severeCongestion = 4
}

/// The degree of passenger occupancy of the vehicle.
public enum RTOccupancyStatus: Int, Sendable {
    case empty = 0
    case manySeatsAvailable = 1
    case fewSeatsAvailable = 2
    case standingRoomOnly = 3
    case crushedStandingRoomOnly = 4
    case full = 5
    case notAcceptingPassengers = 6
    case noDataAvailable = 7
    case notBoardable = 8
}

// MARK: - Internal Protobuf Conversions

extension RTTripDescriptor {
    init(from proto: TransitRealtime_TripDescriptor) {
        self.tripID = proto.hasTripID ? proto.tripID : nil
        self.routeID = proto.hasRouteID ? proto.routeID : nil
        self.directionID = proto.hasDirectionID ? UInt(proto.directionID) : nil
        self.startTime = proto.hasStartTime ? proto.startTime : nil
        self.startDate = proto.hasStartDate ? proto.startDate : nil
        self.scheduleRelationship = proto.hasScheduleRelationship
            ? RTScheduleRelationship(rawValue: proto.scheduleRelationship.rawValue)
            : nil
    }
}

extension RTVehicleDescriptor {
    init(from proto: TransitRealtime_VehicleDescriptor) {
        self.id = proto.hasID ? proto.id : nil
        self.label = proto.hasLabel ? proto.label : nil
        self.licensePlate = proto.hasLicensePlate ? proto.licensePlate : nil
        self.wheelchairAccessible = proto.hasWheelchairAccessible
            ? RTWheelchairAccessible(rawValue: proto.wheelchairAccessible.rawValue)
            : nil
    }
}

extension RTPosition {
    init(from proto: TransitRealtime_Position) {
        self.latitude = CLLocationDegrees(proto.latitude)
        self.longitude = CLLocationDegrees(proto.longitude)
        self.bearing = proto.hasBearing ? proto.bearing : nil
        self.odometer = proto.hasOdometer ? proto.odometer : nil
        self.speed = proto.hasSpeed ? proto.speed : nil
    }
}

extension RTTranslatedString {
    init(from proto: TransitRealtime_TranslatedString) {
        self.translations = proto.translation.map { Translation(from: $0) }
    }
}

extension RTTranslatedString.Translation {
    init(from proto: TransitRealtime_TranslatedString.Translation) {
        self.text = proto.text
        self.language = proto.hasLanguage ? proto.language : nil
    }
}

extension RTTimeRange {
    init(from proto: TransitRealtime_TimeRange) {
        self.start = proto.hasStart ? Date(timeIntervalSince1970: TimeInterval(proto.start)) : nil
        self.end = proto.hasEnd ? Date(timeIntervalSince1970: TimeInterval(proto.end)) : nil
    }
}

extension RTEntitySelector {
    init(from proto: TransitRealtime_EntitySelector) {
        self.agencyID = proto.hasAgencyID ? proto.agencyID : nil
        self.routeID = proto.hasRouteID ? proto.routeID : nil
        self.routeType = proto.hasRouteType ? Int(proto.routeType) : nil
        self.trip = proto.hasTrip ? RTTripDescriptor(from: proto.trip) : nil
        self.stopID = proto.hasStopID ? proto.stopID : nil
        self.directionID = proto.hasDirectionID ? UInt(proto.directionID) : nil
    }
}
