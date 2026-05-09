//
//  RealtimeVehicleDescriptor.swift
//  LocomoSwift
//
//  Identifies the physical vehicle servicing a trip.
//

import Foundation

public struct RealtimeVehicleDescriptor: Hashable, Sendable {

    /// Internal system identification of the vehicle. Stable across feed messages
    /// and useful for tracking a given vehicle through its journey.
    public let id: String?

    /// Customer-facing label that should be shown to passengers, e.g. a coach number.
    public let label: String?

    /// License plate of the vehicle.
    public let licensePlate: String?

    /// Wheelchair accessibility advertised in realtime. Overrides the static
    /// GTFS value for the trip.
    public let wheelchairAccessible: WheelchairAccessible?

    public init(
        id: String? = nil,
        label: String? = nil,
        licensePlate: String? = nil,
        wheelchairAccessible: WheelchairAccessible? = nil
    ) {
        self.id = id
        self.label = label
        self.licensePlate = licensePlate
        self.wheelchairAccessible = wheelchairAccessible
    }
}
