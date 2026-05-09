//
//  TripUpdateMapper.swift
//  LocomoSwift
//

import Foundation
import SwiftProtobuf

enum TripUpdateMapper {

    static func mapTripUpdates(from feedMessage: TransitRealtime_FeedMessage) -> [RealtimeTripUpdate] {
        feedMessage.entity.compactMap { entity in
            guard entity.hasTripUpdate, !entity.isDeleted else { return nil }
            return mapTripUpdate(entity.tripUpdate)
        }
    }

    static func mapTripUpdate(_ proto: TransitRealtime_TripUpdate) -> RealtimeTripUpdate {
        RealtimeTripUpdate(
            trip: TripDescriptorMapper.map(proto.trip),
            vehicle: proto.hasVehicle ? VehicleDescriptorMapper.map(proto.vehicle) : nil,
            stopTimeUpdates: proto.stopTimeUpdate.map(mapStopTimeUpdate),
            timestamp: proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : nil,
            delay: proto.hasDelay ? proto.delay : nil,
            tripProperties: proto.hasTripProperties ? mapTripProperties(proto.tripProperties) : nil
        )
    }

    static func mapStopTimeUpdate(_ proto: TransitRealtime_TripUpdate.StopTimeUpdate) -> RealtimeStopTimeUpdate {
        RealtimeStopTimeUpdate(
            stopID: proto.hasStopID ? proto.stopID : nil,
            stopSequence: proto.hasStopSequence ? proto.stopSequence : nil,
            arrival: proto.hasArrival ? mapStopTimeEvent(proto.arrival) : nil,
            departure: proto.hasDeparture ? mapStopTimeEvent(proto.departure) : nil,
            departureOccupancyStatus: proto.hasDepartureOccupancyStatus
                ? OccupancyStatus(rawValue: Int(proto.departureOccupancyStatus.rawValue))
                : nil,
            scheduleRelationship: StopTimeScheduleRelationship(rawValue: Int(proto.scheduleRelationship.rawValue)),
            stopTimeProperties: proto.hasStopTimeProperties ? mapStopTimeProperties(proto.stopTimeProperties) : nil
        )
    }

    private static func mapStopTimeEvent(_ proto: TransitRealtime_TripUpdate.StopTimeEvent) -> RealtimeStopTimeEvent {
        RealtimeStopTimeEvent(
            delay: proto.hasDelay ? proto.delay : nil,
            time: proto.hasTime ? Date(timeIntervalSince1970: TimeInterval(proto.time)) : nil,
            uncertainty: proto.hasUncertainty ? proto.uncertainty : nil,
            scheduledTime: proto.hasScheduledTime ? Date(timeIntervalSince1970: TimeInterval(proto.scheduledTime)) : nil
        )
    }

    private static func mapStopTimeProperties(_ proto: TransitRealtime_TripUpdate.StopTimeUpdate.StopTimeProperties) -> RealtimeStopTimeProperties {
        RealtimeStopTimeProperties(
            assignedStopID: proto.hasAssignedStopID ? proto.assignedStopID : nil,
            stopHeadsign: proto.hasStopHeadsign ? proto.stopHeadsign : nil,
            pickupType: proto.hasPickupType ? DropOffPickupType(rawValue: Int(proto.pickupType.rawValue)) : nil,
            dropOffType: proto.hasDropOffType ? DropOffPickupType(rawValue: Int(proto.dropOffType.rawValue)) : nil
        )
    }

    private static func mapTripProperties(_ proto: TransitRealtime_TripUpdate.TripProperties) -> RealtimeTripProperties {
        RealtimeTripProperties(
            tripID: proto.hasTripID ? proto.tripID : nil,
            startDate: proto.hasStartDate ? proto.startDate : nil,
            startTime: proto.hasStartTime ? proto.startTime : nil,
            shapeID: proto.hasShapeID ? proto.shapeID : nil,
            tripHeadsign: proto.hasTripHeadsign ? proto.tripHeadsign : nil,
            tripShortName: proto.hasTripShortName ? proto.tripShortName : nil
        )
    }
}
