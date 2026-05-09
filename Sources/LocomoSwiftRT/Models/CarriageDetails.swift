//
//  CarriageDetails.swift
//  LocomoSwift
//
//  Per-carriage realtime detail for vehicles composed of several carriages
//  (TGV, Eurostar, double-deck commuter trains…). Experimental in the
//  GTFS-RT spec but already used by several European producers.
//

import Foundation

public struct CarriageDetails: Hashable, Sendable, Identifiable {

    public let id: String?

    /// User-visible label, e.g. `"7712"`, `"Car ABC-32"`.
    public let label: String?

    /// Occupancy status reported for this specific carriage.
    public let occupancyStatus: OccupancyStatus?

    /// Occupancy percentage for this specific carriage.
    /// `nil` when the producer didn't include data
    /// (the proto wire value `-1` is treated as missing).
    public let occupancyPercentage: Int32?

    /// Order of this carriage in the direction of travel. The first carriage
    /// has value `1`, the second `2`, and so on. Required by the GTFS-RT spec.
    public let carriageSequence: UInt32

    public init(
        id: String? = nil,
        label: String? = nil,
        occupancyStatus: OccupancyStatus? = nil,
        occupancyPercentage: Int32? = nil,
        carriageSequence: UInt32
    ) {
        self.id = id
        self.label = label
        self.occupancyStatus = occupancyStatus
        self.occupancyPercentage = occupancyPercentage
        self.carriageSequence = carriageSequence
    }
}
