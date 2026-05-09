//
//  VehicleDescriptorMapper.swift
//  LocomoSwift
//

import Foundation

enum VehicleDescriptorMapper {

    static func map(_ proto: TransitRealtime_VehicleDescriptor) -> RealtimeVehicleDescriptor {
        let wheelchair: WheelchairAccessible?
        if proto.hasWheelchairAccessible {
            wheelchair = WheelchairAccessible(rawValue: Int(proto.wheelchairAccessible.rawValue))
        } else {
            wheelchair = nil
        }
        return RealtimeVehicleDescriptor(
            id: proto.hasID ? proto.id : nil,
            label: proto.hasLabel ? proto.label : nil,
            licensePlate: proto.hasLicensePlate ? proto.licensePlate : nil,
            wheelchairAccessible: wheelchair
        )
    }
}
