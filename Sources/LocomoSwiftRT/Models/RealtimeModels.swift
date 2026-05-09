//
//  RealtimeModels.swift
//  LocomoSwift
//
//  Domain models exposed by LocomoSwiftRT after mapping a protobuf FeedMessage.
//

import Foundation

// MARK: - StopTimeProperties

/// Updated stop-time properties — pickup type, headsign, assigned platform.
public struct RealtimeStopTimeProperties: Hashable, Sendable {
    /// Real-time stop reassignment (e.g. platform change). Refers to a `stop_id`
    /// from the static GTFS `stops.txt`.
    public let assignedStopID: String?
    public let stopHeadsign: String?
    public let pickupType: DropOffPickupType?
    public let dropOffType: DropOffPickupType?

    public init(
        assignedStopID: String? = nil,
        stopHeadsign: String? = nil,
        pickupType: DropOffPickupType? = nil,
        dropOffType: DropOffPickupType? = nil
    ) {
        self.assignedStopID = assignedStopID
        self.stopHeadsign = stopHeadsign
        self.pickupType = pickupType
        self.dropOffType = dropOffType
    }
}

// MARK: - StopTimeEvent

/// A predicted arrival or departure event for a stop on a trip.
public struct RealtimeStopTimeEvent: Hashable, Sendable {
    /// Schedule deviation in seconds (positive = late, negative = ahead).
    public let delay: Int32?

    /// Absolute predicted time as a Unix-epoch instant.
    public let time: Date?

    /// Prediction's expected error in seconds. `0` means "completely certain"
    /// (computer-controlled timing). `nil` means "unknown".
    public let uncertainty: Int32?

    /// Scheduled time for `NEW`, `REPLACEMENT`, or `DUPLICATED` trips.
    public let scheduledTime: Date?

    public init(
        delay: Int32? = nil,
        time: Date? = nil,
        uncertainty: Int32? = nil,
        scheduledTime: Date? = nil
    ) {
        self.delay = delay
        self.time = time
        self.uncertainty = uncertainty
        self.scheduledTime = scheduledTime
    }
}

// MARK: - StopTimeUpdate

public struct RealtimeStopTimeUpdate: Identifiable, Sendable, Hashable {
    public let id = UUID()

    /// `stop_id` from the corresponding GTFS feed.
    public let stopID: String?

    /// `stop_sequence` from the corresponding GTFS feed. Either `stopID`
    /// or `stopSequence` (or both) must identify the stop.
    public let stopSequence: UInt32?

    public let arrival: RealtimeStopTimeEvent?
    public let departure: RealtimeStopTimeEvent?

    /// Expected occupancy after departure from this stop.
    public let departureOccupancyStatus: OccupancyStatus?

    public let scheduleRelationship: StopTimeScheduleRelationship

    /// Realtime-updated stop time properties (assigned platform, headsign…).
    public let stopTimeProperties: RealtimeStopTimeProperties?

    public init(
        stopID: String? = nil,
        stopSequence: UInt32? = nil,
        arrival: RealtimeStopTimeEvent? = nil,
        departure: RealtimeStopTimeEvent? = nil,
        departureOccupancyStatus: OccupancyStatus? = nil,
        scheduleRelationship: StopTimeScheduleRelationship = .scheduled,
        stopTimeProperties: RealtimeStopTimeProperties? = nil
    ) {
        self.stopID = stopID
        self.stopSequence = stopSequence
        self.arrival = arrival
        self.departure = departure
        self.departureOccupancyStatus = departureOccupancyStatus
        self.scheduleRelationship = scheduleRelationship
        self.stopTimeProperties = stopTimeProperties
    }

    public static func == (lhs: RealtimeStopTimeUpdate, rhs: RealtimeStopTimeUpdate) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: Convenience accessors

    public var arrivalDelay: Int32? { arrival?.delay }
    public var departureDelay: Int32? { departure?.delay }
    public var arrivalTime: Date? { arrival?.time }
    public var departureTime: Date? { departure?.time }
}

// MARK: - TripProperties

public struct RealtimeTripProperties: Hashable, Sendable {
    /// Trip ID for a `DUPLICATED` trip — must differ from the static GTFS one.
    public let tripID: String?
    /// Service date for a `DUPLICATED` trip in `YYYYMMDD`.
    public let startDate: String?
    /// Departure start time for a `DUPLICATED` trip (e.g. `"10:30:00"`).
    public let startTime: String?
    /// Updated shape id for a detour, or for a real-time-only shape.
    public let shapeID: String?
    public let tripHeadsign: String?
    public let tripShortName: String?

    public init(
        tripID: String? = nil,
        startDate: String? = nil,
        startTime: String? = nil,
        shapeID: String? = nil,
        tripHeadsign: String? = nil,
        tripShortName: String? = nil
    ) {
        self.tripID = tripID
        self.startDate = startDate
        self.startTime = startTime
        self.shapeID = shapeID
        self.tripHeadsign = tripHeadsign
        self.tripShortName = tripShortName
    }
}

// MARK: - TripUpdate

public struct RealtimeTripUpdate: Identifiable, Sendable, Hashable {
    public let id = UUID()

    public let trip: RealtimeTripDescriptor
    public let vehicle: RealtimeVehicleDescriptor?
    public let stopTimeUpdates: [RealtimeStopTimeUpdate]
    public let timestamp: Date?
    public let delay: Int32?
    public let tripProperties: RealtimeTripProperties?

    public init(
        trip: RealtimeTripDescriptor,
        vehicle: RealtimeVehicleDescriptor? = nil,
        stopTimeUpdates: [RealtimeStopTimeUpdate] = [],
        timestamp: Date? = nil,
        delay: Int32? = nil,
        tripProperties: RealtimeTripProperties? = nil
    ) {
        self.trip = trip
        self.vehicle = vehicle
        self.stopTimeUpdates = stopTimeUpdates
        self.timestamp = timestamp
        self.delay = delay
        self.tripProperties = tripProperties
    }

    public static func == (lhs: RealtimeTripUpdate, rhs: RealtimeTripUpdate) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: Convenience accessors

    public var tripID: String? { trip.tripID }
    public var routeID: String? { trip.routeID }
    public var scheduleRelationship: TripScheduleRelationship? { trip.scheduleRelationship }
    public var vehicleID: String? { vehicle?.id }
}

// MARK: - VehiclePosition

public struct RealtimeVehiclePosition: Identifiable, Sendable, Hashable {
    public let id = UUID()

    public let trip: RealtimeTripDescriptor?
    public let vehicle: RealtimeVehicleDescriptor

    public let latitude: Double?
    public let longitude: Double?
    public let bearing: Float?
    public let odometer: Double?
    public let speed: Float?

    public let currentStopSequence: UInt32?
    public let stopID: String?
    public let currentStatus: VehicleStopStatus

    public let timestamp: Date?

    public let congestionLevel: CongestionLevel?
    public let occupancyStatus: OccupancyStatus?
    public let occupancyPercentage: UInt32?

    public let multiCarriageDetails: [CarriageDetails]

    public init(
        trip: RealtimeTripDescriptor? = nil,
        vehicle: RealtimeVehicleDescriptor,
        latitude: Double? = nil,
        longitude: Double? = nil,
        bearing: Float? = nil,
        odometer: Double? = nil,
        speed: Float? = nil,
        currentStopSequence: UInt32? = nil,
        stopID: String? = nil,
        currentStatus: VehicleStopStatus = .inTransitTo,
        timestamp: Date? = nil,
        congestionLevel: CongestionLevel? = nil,
        occupancyStatus: OccupancyStatus? = nil,
        occupancyPercentage: UInt32? = nil,
        multiCarriageDetails: [CarriageDetails] = []
    ) {
        self.trip = trip
        self.vehicle = vehicle
        self.latitude = latitude
        self.longitude = longitude
        self.bearing = bearing
        self.odometer = odometer
        self.speed = speed
        self.currentStopSequence = currentStopSequence
        self.stopID = stopID
        self.currentStatus = currentStatus
        self.timestamp = timestamp
        self.congestionLevel = congestionLevel
        self.occupancyStatus = occupancyStatus
        self.occupancyPercentage = occupancyPercentage
        self.multiCarriageDetails = multiCarriageDetails
    }

    public static func == (lhs: RealtimeVehiclePosition, rhs: RealtimeVehiclePosition) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: Convenience accessors

    public var tripID: String? { trip?.tripID }
    public var vehicleID: String? { vehicle.id }
}

// MARK: - Service Alert

public struct AlertActivePeriod: Hashable, Sendable {
    public let start: Date?
    public let end: Date?

    public init(start: Date? = nil, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    /// Returns `true` if the period contains the given date. Open intervals
    /// (no `start` or no `end`) are treated as unbounded on that side.
    public func contains(_ date: Date) -> Bool {
        if let start, date < start { return false }
        if let end, date >= end { return false }
        return true
    }
}

public struct AlertInformedEntity: Hashable, Sendable {
    public let agencyID: String?
    public let routeID: String?
    public let routeType: Int32?
    public let trip: RealtimeTripDescriptor?
    public let stopID: String?
    public let directionID: UInt32?

    public init(
        agencyID: String? = nil,
        routeID: String? = nil,
        routeType: Int32? = nil,
        trip: RealtimeTripDescriptor? = nil,
        stopID: String? = nil,
        directionID: UInt32? = nil
    ) {
        self.agencyID = agencyID
        self.routeID = routeID
        self.routeType = routeType
        self.trip = trip
        self.stopID = stopID
        self.directionID = directionID
    }

    /// Convenience: the `tripID` of the referenced trip, if any.
    public var tripID: String? { trip?.tripID }
}

public struct RealtimeServiceAlert: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let alertID: String

    public let cause: AlertCause?
    public let effect: AlertEffect?
    public let severityLevel: AlertSeverityLevel?

    public let url: TranslatedString?
    public let headerText: TranslatedString?
    public let descriptionText: TranslatedString?

    /// Text-to-speech version of `headerText`.
    public let ttsHeaderText: TranslatedString?
    /// Text-to-speech version of `descriptionText`.
    public let ttsDescriptionText: TranslatedString?

    /// Free-form, agency-specific cause description (more specific than `cause`).
    public let causeDetail: TranslatedString?
    /// Free-form, agency-specific effect description (more specific than `effect`).
    public let effectDetail: TranslatedString?

    public let image: TranslatedImage?
    public let imageAlternativeText: TranslatedString?

    public let activePeriods: [AlertActivePeriod]
    public let informedEntities: [AlertInformedEntity]

    public init(
        alertID: String,
        cause: AlertCause? = nil,
        effect: AlertEffect? = nil,
        severityLevel: AlertSeverityLevel? = nil,
        url: TranslatedString? = nil,
        headerText: TranslatedString? = nil,
        descriptionText: TranslatedString? = nil,
        ttsHeaderText: TranslatedString? = nil,
        ttsDescriptionText: TranslatedString? = nil,
        causeDetail: TranslatedString? = nil,
        effectDetail: TranslatedString? = nil,
        image: TranslatedImage? = nil,
        imageAlternativeText: TranslatedString? = nil,
        activePeriods: [AlertActivePeriod] = [],
        informedEntities: [AlertInformedEntity] = []
    ) {
        self.alertID = alertID
        self.cause = cause
        self.effect = effect
        self.severityLevel = severityLevel
        self.url = url
        self.headerText = headerText
        self.descriptionText = descriptionText
        self.ttsHeaderText = ttsHeaderText
        self.ttsDescriptionText = ttsDescriptionText
        self.causeDetail = causeDetail
        self.effectDetail = effectDetail
        self.image = image
        self.imageAlternativeText = imageAlternativeText
        self.activePeriods = activePeriods
        self.informedEntities = informedEntities
    }

    public static func == (lhs: RealtimeServiceAlert, rhs: RealtimeServiceAlert) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Convenience: returns `true` if the alert is active at the given date,
    /// based on its declared ``activePeriods``.
    /// An alert with no active period is considered always active.
    public func isActive(at date: Date = Date()) -> Bool {
        if activePeriods.isEmpty { return true }
        return activePeriods.contains { $0.contains(date) }
    }
}
