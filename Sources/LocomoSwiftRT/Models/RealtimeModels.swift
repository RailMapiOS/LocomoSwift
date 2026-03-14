//
//  RealtimeManager.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation
import SwiftProtobuf

public struct RealtimeTripUpdate: Identifiable, Sendable {
    public let id = UUID()
    public let tripID: String
    public let routeID: String?
    public let scheduleRelationship: TripScheduleRelationship
    public let stopTimeUpdates: [RealtimeStopTimeUpdate]
    public let timestamp: Date
    public let delay: Int32? // en secondes
    public let vehicleID: String?
    
    public init(
        tripID: String,
        routeID: String? = nil,
        scheduleRelationship: TripScheduleRelationship,
        stopTimeUpdates: [RealtimeStopTimeUpdate],
        timestamp: Date,
        delay: Int32? = nil,
        vehicleID: String? = nil
    ) {
        self.tripID = tripID
        self.routeID = routeID
        self.scheduleRelationship = scheduleRelationship
        self.stopTimeUpdates = stopTimeUpdates
        self.timestamp = timestamp
        self.delay = delay
        self.vehicleID = vehicleID
    }
}

public struct RealtimeStopTimeUpdate: Identifiable, Sendable {
    public let id = UUID()
    public let stopID: String
    public let stopSequence: UInt32?
    public let arrivalDelay: Int32?
    public let departureDelay: Int32?
    public let arrivalTime: Date?
    public let departureTime: Date?
    public let scheduleRelationship: StopTimeScheduleRelationship
    
    public init(
        stopID: String,
        stopSequence: UInt32?,
        arrivalDelay: Int32?,
        departureDelay: Int32?,
        arrivalTime: Date?,
        departureTime: Date?,
        scheduleRelationship: StopTimeScheduleRelationship
    ) {
        self.stopID = stopID
        self.stopSequence = stopSequence
        self.arrivalDelay = arrivalDelay
        self.departureDelay = departureDelay
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
        self.scheduleRelationship = scheduleRelationship
    }
}

public struct RealtimeVehiclePosition: Identifiable, Sendable {
    public let id = UUID()
    public let tripID: String?
    public let vehicleID: String
    public let latitude: Double?
    public let longitude: Double?
    public let bearing: Float?
    public let speed: Float?
    public let currentStopSequence: UInt32?
    public let currentStatus: VehicleStopStatus
    public let timestamp: Date
    public let occupancyStatus: OccupancyStatus?
    
    public init(
        tripID: String?,
        vehicleID: String,
        latitude: Double?,
        longitude: Double?,
        bearing: Float?,
        speed: Float?,
        currentStopSequence: UInt32?,
        currentStatus: VehicleStopStatus,
        timestamp: Date,
        occupancyStatus: OccupancyStatus?
    ) {
        self.tripID = tripID
        self.vehicleID = vehicleID
        self.latitude = latitude
        self.longitude = longitude
        self.bearing = bearing
        self.speed = speed
        self.currentStopSequence = currentStopSequence
        self.currentStatus = currentStatus
        self.timestamp = timestamp
        self.occupancyStatus = occupancyStatus
    }
}

public struct RealtimeServiceAlert: Identifiable, Sendable {
    public let id = UUID()
    public let alertID: String
    public let cause: AlertCause?
    public let effect: AlertEffect?
    public let url: URL?
    public let headerText: String?
    public let descriptionText: String?
    public let activePeriods: [AlertActivePeriod]
    public let informedEntities: [AlertInformedEntity]
    
    public init(
        alertID: String,
        cause: AlertCause?,
        effect: AlertEffect?,
        url: URL?,
        headerText: String?,
        descriptionText: String?,
        activePeriods: [AlertActivePeriod],
        informedEntities: [AlertInformedEntity]
    ) {
        self.alertID = alertID
        self.cause = cause
        self.effect = effect
        self.url = url
        self.headerText = headerText
        self.descriptionText = descriptionText
        self.activePeriods = activePeriods
        self.informedEntities = informedEntities
    }
}

public struct AlertActivePeriod: Sendable {
    public let start: Date?
    public let end: Date?
    
    public init(start: Date?, end: Date?) {
        self.start = start
        self.end = end
    }
}

public struct AlertInformedEntity: Sendable {
    public let agencyID: String?
    public let routeID: String?
    public let routeType: Int32?
    public let tripID: String?
    public let stopID: String?
    public let directionID: UInt32?
    
    public init(
        agencyID: String?,
        routeID: String?,
        routeType: Int32?,
        tripID: String?,
        stopID: String?,
        directionID: UInt32?
    ) {
        self.agencyID = agencyID
        self.routeID = routeID
        self.routeType = routeType
        self.tripID = tripID
        self.stopID = stopID
        self.directionID = directionID
    }
}
