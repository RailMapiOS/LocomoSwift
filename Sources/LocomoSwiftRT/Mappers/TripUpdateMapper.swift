//
//  TripUpdateMapper.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation
import SwiftProtobuf

public struct TripUpdateMapper {
    
    static func mapTripUpdates(from feedMessage: TransitRealtime_FeedMessage) -> [RealtimeTripUpdate] {
        return feedMessage.entity.compactMap { entity in
            guard entity.hasTripUpdate else { return nil }
            return mapTripUpdate(entity.tripUpdate)
        }
    }
    
    private static func mapTripUpdate(_ tripUpdate: TransitRealtime_TripUpdate) -> RealtimeTripUpdate {
        let stopTimeUpdates = tripUpdate.stopTimeUpdate.map { mapStopTimeUpdate($0) }
        
        let scheduleRelationship = TripScheduleRelationship(
            rawValue: Int(tripUpdate.trip.scheduleRelationship.rawValue)
        ) ?? .scheduled
        
        return RealtimeTripUpdate(
            tripID: tripUpdate.trip.tripID,
            routeID: tripUpdate.trip.hasRouteID ? tripUpdate.trip.routeID : nil,
            scheduleRelationship: scheduleRelationship,
            stopTimeUpdates: stopTimeUpdates,
            timestamp: Date(timeIntervalSince1970: TimeInterval(tripUpdate.timestamp)),
            delay: tripUpdate.hasDelay ? tripUpdate.delay : nil,
            vehicleID: tripUpdate.hasVehicle ? tripUpdate.vehicle.id : nil
        )
    }
    
    private static func mapStopTimeUpdate(_ stopTimeUpdate: TransitRealtime_TripUpdate.StopTimeUpdate) -> RealtimeStopTimeUpdate {
        let arrivalDelay = stopTimeUpdate.hasArrival && stopTimeUpdate.arrival.hasDelay ? stopTimeUpdate.arrival.delay : nil
        let departureDelay = stopTimeUpdate.hasDeparture && stopTimeUpdate.departure.hasDelay ? stopTimeUpdate.departure.delay : nil
        
        let arrivalTime = stopTimeUpdate.hasArrival && stopTimeUpdate.arrival.hasTime ? 
            Date(timeIntervalSince1970: TimeInterval(stopTimeUpdate.arrival.time)) : nil
        let departureTime = stopTimeUpdate.hasDeparture && stopTimeUpdate.departure.hasTime ? 
            Date(timeIntervalSince1970: TimeInterval(stopTimeUpdate.departure.time)) : nil
        
        let scheduleRelationship = StopTimeScheduleRelationship(
            rawValue: Int(stopTimeUpdate.scheduleRelationship.rawValue)
        ) ?? .scheduled
        
        return RealtimeStopTimeUpdate(
            stopID: stopTimeUpdate.stopID,
            stopSequence: stopTimeUpdate.hasStopSequence ? stopTimeUpdate.stopSequence : nil,
            arrivalDelay: arrivalDelay,
            departureDelay: departureDelay,
            arrivalTime: arrivalTime,
            departureTime: departureTime,
            scheduleRelationship: scheduleRelationship
        )
    }
}
