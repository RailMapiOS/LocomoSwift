//
//  RealtimeEnums.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation

public enum TripScheduleRelationship: Int, CaseIterable, Sendable {
    case scheduled = 0
    case added = 1
    case unscheduled = 2
    case cancelled = 3
    case replacement = 5
    case duplicated = 6
}

public enum StopTimeScheduleRelationship: Int, CaseIterable, Sendable {
    case scheduled = 0
    case skipped = 1
    case noData = 2
    case unscheduled = 3
}

public enum VehicleStopStatus: Int, CaseIterable, Sendable {
    case incomingAt = 0
    case stoppedAt = 1
    case inTransitTo = 2
}

public enum OccupancyStatus: Int, CaseIterable, Sendable {
    case empty = 0
    case manySeatsAvailable = 1
    case feawSeatsAvailable = 2
    case standingRoomOnly = 3
    case crushedStandingRoomOnly = 4
    case full = 5
    case notAcceptingPassengers = 6
    case noDataAvailable = 7
    case notBoardable = 8
}

public enum AlertCause: Int, CaseIterable, Sendable {
    case unknownCause = 1
    case otherCause = 2
    case technicalProblem = 3
    case strike = 4
    case demonstration = 5
    case accident = 6
    case holiday = 7
    case weather = 8
    case maintenance = 9
    case constrction = 10
    case policeActivity = 11
    case medicalEmergency = 12
}

public enum AlertEffect: Int, CaseIterable, Sendable {
    case noService = 1
    case reducedService = 2
    case significantDelays = 3
    case detour = 4
    case additionalService = 5
    case modifiedService = 6
    case otherEffect = 7
    case unknownEffect = 8
    case stopMoved = 9
    case noEffect = 10
    case accessibilityIssue = 11
}
