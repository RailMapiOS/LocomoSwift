//
//  VehiclePositionMapper.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//


import Foundation
import SwiftProtobuf

public struct VehiclePositionMapper {
    
    static func mapVehiclePositions(from feedMessage: TransitRealtime_FeedMessage) -> [RealtimeVehiclePosition] {
        return feedMessage.entity.compactMap { entity in
            guard entity.hasVehicle else { return nil }
            return mapVehiclePosition(entity.vehicle)
        }
    }
    
    private static func mapVehiclePosition(_ vehiclePosition: TransitRealtime_VehiclePosition) -> RealtimeVehiclePosition {
        let latitude = vehiclePosition.hasPosition ? Double(vehiclePosition.position.latitude) : nil
        let longitude = vehiclePosition.hasPosition ? Double(vehiclePosition.position.longitude) : nil
        let bearing = vehiclePosition.hasPosition && vehiclePosition.position.hasBearing ? vehiclePosition.position.bearing : nil
        let speed = vehiclePosition.hasPosition && vehiclePosition.position.hasSpeed ? vehiclePosition.position.speed : nil
        
        let currentStatus = VehicleStopStatus(
            rawValue: Int(vehiclePosition.currentStatus.rawValue)
        ) ?? .inTransitTo
        
        let occupancyStatus = vehiclePosition.hasOccupancyStatus ? 
            OccupancyStatus(rawValue: Int(vehiclePosition.occupancyStatus.rawValue)) : nil
        
        return RealtimeVehiclePosition(
            tripID: vehiclePosition.hasTrip ? vehiclePosition.trip.tripID : nil,
            vehicleID: vehiclePosition.vehicle.id,
            latitude: latitude,
            longitude: longitude,
            bearing: bearing,
            speed: speed,
            currentStopSequence: vehiclePosition.hasCurrentStopSequence ? vehiclePosition.currentStopSequence : nil,
            currentStatus: currentStatus,
            timestamp: Date(timeIntervalSince1970: TimeInterval(vehiclePosition.timestamp)),
            occupancyStatus: occupancyStatus
        )
    }
}
