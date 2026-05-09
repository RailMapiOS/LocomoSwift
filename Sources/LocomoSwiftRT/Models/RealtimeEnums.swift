//
//  RealtimeEnums.swift
//  LocomoSwift
//
//  GTFS Realtime enums.
//
//  Closed enums (`Int`-backed) are used for values whose set is fixed by
//  the GTFS Realtime spec and unlikely to grow. Extensible enums use the
//  `.unrecognized(rawValue:)` pattern so that future spec additions don't
//  silently get dropped — consumers can still inspect the raw integer.
//

import Foundation

// MARK: - Closed enums (full spec coverage, unlikely to change)

/// Determines whether the current fetch is incremental.
public enum Incrementality: Int, CaseIterable, Sendable {
    case fullDataset = 0
    case differential = 1
}

/// Wheelchair accessibility advertised by a Realtime feed for the served trip.
public enum WheelchairAccessible: Int, CaseIterable, Sendable {
    case noValue = 0
    case unknown = 1
    case accessible = 2
    case inaccessible = 3
}

/// Updated pickup/drop-off rule for a stop.
public enum DropOffPickupType: Int, CaseIterable, Sendable {
    case regular = 0
    case none = 1
    case phoneAgency = 2
    case coordinateWithDriver = 3
}

/// Vehicle status with respect to its current stop.
public enum VehicleStopStatus: Int, CaseIterable, Sendable {
    case incomingAt = 0
    case stoppedAt = 1
    case inTransitTo = 2
}

/// Severity advertised by an alert.
public enum AlertSeverityLevel: Int, CaseIterable, Sendable {
    case unknown = 1
    case info = 2
    case warning = 3
    case severe = 4
}

// MARK: - Extensible enums (`.unrecognized(rawValue:)`)
//
// These mirror GTFS-RT enums whose values can grow with newer spec revisions.
// Using `unrecognized(rawValue:)` lets consumers handle future cases without
// the package having to ship a new release each time.

/// Schedule relationship for a trip.
public enum TripScheduleRelationship: Hashable, Sendable {
    case scheduled
    /// Deprecated by GTFS-RT spec — prefer `.duplicated` (extra trip identical
    /// to a scheduled one with different start) or `.new` (extra unrelated trip).
    case added
    case unscheduled
    case canceled
    case replacement
    case duplicated
    case deleted
    case new
    case unrecognized(rawValue: Int)

    public var rawValue: Int {
        switch self {
        case .scheduled: return 0
        case .added: return 1
        case .unscheduled: return 2
        case .canceled: return 3
        case .replacement: return 5
        case .duplicated: return 6
        case .deleted: return 7
        case .new: return 8
        case .unrecognized(let raw): return raw
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .scheduled
        case 1: self = .added
        case 2: self = .unscheduled
        case 3: self = .canceled
        case 5: self = .replacement
        case 6: self = .duplicated
        case 7: self = .deleted
        case 8: self = .new
        default: self = .unrecognized(rawValue: rawValue)
        }
    }
}

/// Schedule relationship for a stop time event.
public enum StopTimeScheduleRelationship: Hashable, Sendable {
    case scheduled
    case skipped
    case noData
    case unscheduled
    case unrecognized(rawValue: Int)

    public var rawValue: Int {
        switch self {
        case .scheduled: return 0
        case .skipped: return 1
        case .noData: return 2
        case .unscheduled: return 3
        case .unrecognized(let raw): return raw
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .scheduled
        case 1: self = .skipped
        case 2: self = .noData
        case 3: self = .unscheduled
        default: self = .unrecognized(rawValue: rawValue)
        }
    }
}

/// Cause of an alert.
public enum AlertCause: Hashable, Sendable {
    case unknown
    case other
    case technicalProblem
    case strike
    case demonstration
    case accident
    case holiday
    case weather
    case maintenance
    case construction
    case policeActivity
    case medicalEmergency
    case unrecognized(rawValue: Int)

    public var rawValue: Int {
        switch self {
        case .unknown: return 1
        case .other: return 2
        case .technicalProblem: return 3
        case .strike: return 4
        case .demonstration: return 5
        case .accident: return 6
        case .holiday: return 7
        case .weather: return 8
        case .maintenance: return 9
        case .construction: return 10
        case .policeActivity: return 11
        case .medicalEmergency: return 12
        case .unrecognized(let raw): return raw
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 1: self = .unknown
        case 2: self = .other
        case 3: self = .technicalProblem
        case 4: self = .strike
        case 5: self = .demonstration
        case 6: self = .accident
        case 7: self = .holiday
        case 8: self = .weather
        case 9: self = .maintenance
        case 10: self = .construction
        case 11: self = .policeActivity
        case 12: self = .medicalEmergency
        default: self = .unrecognized(rawValue: rawValue)
        }
    }
}

/// Effect of an alert on the affected entity.
public enum AlertEffect: Hashable, Sendable {
    case noService
    case reducedService
    case significantDelays
    case detour
    case additionalService
    case modifiedService
    case otherEffect
    case unknownEffect
    case stopMoved
    case noEffect
    case accessibilityIssue
    case unrecognized(rawValue: Int)

    public var rawValue: Int {
        switch self {
        case .noService: return 1
        case .reducedService: return 2
        case .significantDelays: return 3
        case .detour: return 4
        case .additionalService: return 5
        case .modifiedService: return 6
        case .otherEffect: return 7
        case .unknownEffect: return 8
        case .stopMoved: return 9
        case .noEffect: return 10
        case .accessibilityIssue: return 11
        case .unrecognized(let raw): return raw
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 1: self = .noService
        case 2: self = .reducedService
        case 3: self = .significantDelays
        case 4: self = .detour
        case 5: self = .additionalService
        case 6: self = .modifiedService
        case 7: self = .otherEffect
        case 8: self = .unknownEffect
        case 9: self = .stopMoved
        case 10: self = .noEffect
        case 11: self = .accessibilityIssue
        default: self = .unrecognized(rawValue: rawValue)
        }
    }
}

/// Congestion level affecting a vehicle (traffic), distinct from passenger occupancy.
public enum CongestionLevel: Hashable, Sendable {
    case unknown
    case runningSmoothly
    case stopAndGo
    case congestion
    /// People leaving their cars.
    case severeCongestion
    case unrecognized(rawValue: Int)

    public var rawValue: Int {
        switch self {
        case .unknown: return 0
        case .runningSmoothly: return 1
        case .stopAndGo: return 2
        case .congestion: return 3
        case .severeCongestion: return 4
        case .unrecognized(let raw): return raw
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .unknown
        case 1: self = .runningSmoothly
        case 2: self = .stopAndGo
        case 3: self = .congestion
        case 4: self = .severeCongestion
        default: self = .unrecognized(rawValue: rawValue)
        }
    }
}

/// Passenger occupancy state for a vehicle or carriage.
public enum OccupancyStatus: Hashable, Sendable {
    case empty
    case manySeatsAvailable
    case fewSeatsAvailable
    case standingRoomOnly
    case crushedStandingRoomOnly
    case full
    case notAcceptingPassengers
    case noDataAvailable
    case notBoardable
    case unrecognized(rawValue: Int)

    public var rawValue: Int {
        switch self {
        case .empty: return 0
        case .manySeatsAvailable: return 1
        case .fewSeatsAvailable: return 2
        case .standingRoomOnly: return 3
        case .crushedStandingRoomOnly: return 4
        case .full: return 5
        case .notAcceptingPassengers: return 6
        case .noDataAvailable: return 7
        case .notBoardable: return 8
        case .unrecognized(let raw): return raw
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .empty
        case 1: self = .manySeatsAvailable
        case 2: self = .fewSeatsAvailable
        case 3: self = .standingRoomOnly
        case 4: self = .crushedStandingRoomOnly
        case 5: self = .full
        case 6: self = .notAcceptingPassengers
        case 7: self = .noDataAvailable
        case 8: self = .notBoardable
        default: self = .unrecognized(rawValue: rawValue)
        }
    }
}
