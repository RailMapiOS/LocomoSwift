//
//  RealtimeDataSource.swift
//  LocomoSwift
//
//  Three small protocols (ISP) describing what a realtime data source can do.
//  The umbrella `RealtimeDataSource` typealias preserves the original API
//  surface so existing consumers don't have to update their conformances.
//

import Foundation
import LocomoSwiftGTFS

/// Fetches GTFS Realtime trip updates from a configured ``DataSource``.
public protocol TripUpdateFetching {
    func fetchTripUpdates(from source: DataSource) async throws -> [RealtimeTripUpdate]
}

/// Fetches GTFS Realtime vehicle positions from a configured ``DataSource``.
public protocol VehiclePositionFetching {
    func fetchVehiclePositions(from source: DataSource) async throws -> [RealtimeVehiclePosition]
}

/// Fetches GTFS Realtime service alerts from a configured ``DataSource``.
public protocol ServiceAlertFetching {
    func fetchServiceAlerts(from source: DataSource) async throws -> [RealtimeServiceAlert]
}

/// Fetches an entire GTFS Realtime feed (header + every entity type) in one call.
public protocol RealtimeFeedFetching {
    func fetchFeed(from source: DataSource, feedType: RealtimeFeedType) async throws -> RealtimeFeed
}

/// Convenience composition — every realtime source typically conforms to all
/// four protocols. Consumers can still depend on the smaller protocols if they
/// only need a subset (preserves the Interface Segregation Principle).
public typealias RealtimeDataSource = TripUpdateFetching & VehiclePositionFetching & ServiceAlertFetching & RealtimeFeedFetching
