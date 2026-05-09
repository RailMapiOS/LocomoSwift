//
//  VehiclePositionMapper.swift
//  LocomoSwift
//

import Foundation
import SwiftProtobuf

enum VehiclePositionMapper {

    static func mapVehiclePositions(from feedMessage: TransitRealtime_FeedMessage) -> [RealtimeVehiclePosition] {
        feedMessage.entity.compactMap { entity in
            guard entity.hasVehicle, !entity.isDeleted else { return nil }
            return mapVehiclePosition(entity.vehicle)
        }
    }

    static func mapVehiclePosition(_ proto: TransitRealtime_VehiclePosition) -> RealtimeVehiclePosition {
        let position: TransitRealtime_Position? = proto.hasPosition ? proto.position : nil

        return RealtimeVehiclePosition(
            trip: proto.hasTrip ? TripDescriptorMapper.map(proto.trip) : nil,
            vehicle: VehicleDescriptorMapper.map(proto.vehicle),
            latitude: position.flatMap { $0.hasLatitude ? Double($0.latitude) : nil },
            longitude: position.flatMap { $0.hasLongitude ? Double($0.longitude) : nil },
            bearing: position.flatMap { $0.hasBearing ? $0.bearing : nil },
            odometer: position.flatMap { $0.hasOdometer ? $0.odometer : nil },
            speed: position.flatMap { $0.hasSpeed ? $0.speed : nil },
            currentStopSequence: proto.hasCurrentStopSequence ? proto.currentStopSequence : nil,
            stopID: proto.hasStopID ? proto.stopID : nil,
            currentStatus: VehicleStopStatus(rawValue: Int(proto.currentStatus.rawValue)) ?? .inTransitTo,
            timestamp: proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : nil,
            congestionLevel: proto.hasCongestionLevel
                ? CongestionLevel(rawValue: Int(proto.congestionLevel.rawValue))
                : nil,
            occupancyStatus: proto.hasOccupancyStatus
                ? OccupancyStatus(rawValue: Int(proto.occupancyStatus.rawValue))
                : nil,
            occupancyPercentage: proto.hasOccupancyPercentage ? proto.occupancyPercentage : nil,
            multiCarriageDetails: proto.multiCarriageDetails.map(mapCarriage)
        )
    }

    private static func mapCarriage(_ proto: TransitRealtime_VehiclePosition.CarriageDetails) -> CarriageDetails {
        // Wire value -1 means "not provided" per the spec.
        let percentage: Int32?
        if proto.hasOccupancyPercentage && proto.occupancyPercentage != -1 {
            percentage = proto.occupancyPercentage
        } else {
            percentage = nil
        }
        return CarriageDetails(
            id: proto.hasID ? proto.id : nil,
            label: proto.hasLabel ? proto.label : nil,
            occupancyStatus: proto.hasOccupancyStatus
                ? OccupancyStatus(rawValue: Int(proto.occupancyStatus.rawValue))
                : nil,
            occupancyPercentage: percentage,
            carriageSequence: proto.hasCarriageSequence ? proto.carriageSequence : 0
        )
    }
}
