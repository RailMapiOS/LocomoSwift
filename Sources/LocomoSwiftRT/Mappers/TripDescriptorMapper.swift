//
//  TripDescriptorMapper.swift
//  LocomoSwift
//

import Foundation

enum TripDescriptorMapper {

    static func map(_ proto: TransitRealtime_TripDescriptor) -> RealtimeTripDescriptor {
        RealtimeTripDescriptor(
            tripID: proto.hasTripID ? proto.tripID : nil,
            routeID: proto.hasRouteID ? proto.routeID : nil,
            directionID: proto.hasDirectionID ? proto.directionID : nil,
            startTime: proto.hasStartTime ? proto.startTime : nil,
            startDate: proto.hasStartDate ? proto.startDate : nil,
            scheduleRelationship: proto.hasScheduleRelationship
                ? TripScheduleRelationship(rawValue: Int(proto.scheduleRelationship.rawValue))
                : nil,
            modifiedTrip: proto.hasModifiedTrip ? mapModifiedTrip(proto.modifiedTrip) : nil
        )
    }

    private static func mapModifiedTrip(_ proto: TransitRealtime_TripDescriptor.ModifiedTripSelector) -> RealtimeTripDescriptor.ModifiedTripSelector {
        RealtimeTripDescriptor.ModifiedTripSelector(
            modificationsID: proto.hasModificationsID ? proto.modificationsID : nil,
            affectedTripID: proto.hasAffectedTripID ? proto.affectedTripID : nil,
            startTime: proto.hasStartTime ? proto.startTime : nil,
            startDate: proto.hasStartDate ? proto.startDate : nil
        )
    }
}
