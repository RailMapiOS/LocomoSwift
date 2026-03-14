//
//  RealtimeVehiclePosition.swift
//  LocomoSwift
//
//  Created by LocomoSwift on 2024.
//

import Foundation

/// Realtime positioning information for a given vehicle.
public struct RTVehiclePosition: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// The trip this vehicle is serving.
    public let trip: RTTripDescriptor?
    /// Additional information on the vehicle serving this trip.
    public let vehicle: RTVehicleDescriptor?
    /// Current position of this vehicle.
    public let position: RTPosition?
    /// The stop sequence index of the current stop.
    public let currentStopSequence: UInt?
    /// Identifies the current stop.
    public let stopID: LSID?
    /// The exact status of the vehicle with respect to the current stop.
    public let currentStatus: RTVehicleStopStatus
    /// Moment at which the vehicle's position was measured.
    public let timestamp: Date?
    /// Congestion level that is affecting this vehicle.
    public let congestionLevel: RTCongestionLevel?
    /// Passenger occupancy status.
    public let occupancyStatus: RTOccupancyStatus?
    /// Percentage of seats occupied (0-100).
    public let occupancyPercentage: UInt?
    /// Details about individual carriages of this vehicle.
    public let multiCarriageDetails: [CarriageDetails]

    public init(id: UUID = UUID(), trip: RTTripDescriptor? = nil, vehicle: RTVehicleDescriptor? = nil,
                position: RTPosition? = nil, currentStopSequence: UInt? = nil, stopID: LSID? = nil,
                currentStatus: RTVehicleStopStatus = .inTransitTo, timestamp: Date? = nil,
                congestionLevel: RTCongestionLevel? = nil, occupancyStatus: RTOccupancyStatus? = nil,
                occupancyPercentage: UInt? = nil, multiCarriageDetails: [CarriageDetails] = []) {
        self.id = id
        self.trip = trip
        self.vehicle = vehicle
        self.position = position
        self.currentStopSequence = currentStopSequence
        self.stopID = stopID
        self.currentStatus = currentStatus
        self.timestamp = timestamp
        self.congestionLevel = congestionLevel
        self.occupancyStatus = occupancyStatus
        self.occupancyPercentage = occupancyPercentage
        self.multiCarriageDetails = multiCarriageDetails
    }

    // MARK: - CarriageDetails

    /// Carriage specific details, used for multi-carriage vehicles.
    public struct CarriageDetails: Hashable, Sendable {
        public let carriageID: String?
        public let label: String?
        public let occupancyStatus: RTOccupancyStatus
        public let occupancyPercentage: Int?
        public let carriageSequence: UInt?

        public init(carriageID: String? = nil, label: String? = nil,
                    occupancyStatus: RTOccupancyStatus = .noDataAvailable,
                    occupancyPercentage: Int? = nil, carriageSequence: UInt? = nil) {
            self.carriageID = carriageID
            self.label = label
            self.occupancyStatus = occupancyStatus
            self.occupancyPercentage = occupancyPercentage
            self.carriageSequence = carriageSequence
        }
    }
}

// MARK: - Internal Protobuf Conversion

extension RTVehiclePosition {
    init(from proto: TransitRealtime_VehiclePosition) {
        self.id = UUID()
        self.trip = proto.hasTrip ? RTTripDescriptor(from: proto.trip) : nil
        self.vehicle = proto.hasVehicle ? RTVehicleDescriptor(from: proto.vehicle) : nil
        self.position = proto.hasPosition ? RTPosition(from: proto.position) : nil
        self.currentStopSequence = proto.hasCurrentStopSequence ? UInt(proto.currentStopSequence) : nil
        self.stopID = proto.hasStopID ? proto.stopID : nil
        self.currentStatus = RTVehicleStopStatus(rawValue: proto.currentStatus.rawValue) ?? .inTransitTo
        self.timestamp = proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : nil
        self.congestionLevel = proto.hasCongestionLevel ? RTCongestionLevel(rawValue: proto.congestionLevel.rawValue) : nil
        self.occupancyStatus = proto.hasOccupancyStatus ? RTOccupancyStatus(rawValue: proto.occupancyStatus.rawValue) : nil
        self.occupancyPercentage = proto.hasOccupancyPercentage ? UInt(proto.occupancyPercentage) : nil
        self.multiCarriageDetails = proto.multiCarriageDetails.map { CarriageDetails(from: $0) }
    }
}

extension RTVehiclePosition.CarriageDetails {
    init(from proto: TransitRealtime_VehiclePosition.CarriageDetails) {
        self.carriageID = proto.hasID ? proto.id : nil
        self.label = proto.hasLabel ? proto.label : nil
        self.occupancyStatus = RTOccupancyStatus(rawValue: proto.occupancyStatus.rawValue) ?? .noDataAvailable
        self.occupancyPercentage = proto.hasOccupancyPercentage ? Int(proto.occupancyPercentage) : nil
        self.carriageSequence = proto.hasCarriageSequence ? UInt(proto.carriageSequence) : nil
    }
}
