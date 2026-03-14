//
//  RealtimeDataSource.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//


import Foundation
import LocomoSwiftGTFS

/// Protocol for realtime data sources.
public protocol RealtimeDataSource {

    /// Fetches trip updates from the given source.
    func fetchTripUpdates(from source: DataSource) async throws -> [RealtimeTripUpdate]

    /// Fetches vehicle positions from the given source.
    func fetchVehiclePositions(from source: DataSource) async throws -> [RealtimeVehiclePosition]

    /// Fetches service alerts from the given source.
    func fetchServiceAlerts(from source: DataSource) async throws -> [RealtimeServiceAlert]
}

// MARK: - SIRI SX Lite Preparation

/// SIRI SX Lite data source (future implementation).
//public struct SIRIDataSource: RealtimeDataSource {
//
//    private let baseURL: URL
//
//    public init(baseURL: URL) {
//        self.baseURL = baseURL
//    }
//
//    public func fetchTripUpdates() async throws -> [RealtimeTripUpdate] {
//        // TODO: Implement SIRI to GTFS RT conversion
//        throw RealtimeError.parsingError
//    }
//
//    public func fetchVehiclePositions() async throws -> [RealtimeVehiclePosition] {
//        // TODO: Implement SIRI to GTFS RT conversion
//        throw RealtimeError.parsingError
//    }
//
//    public func fetchServiceAlerts() async throws -> [RealtimeServiceAlert] {
//        // TODO: Implement SIRI to GTFS RT conversion
//        throw RealtimeError.parsingError
//    }
//}
