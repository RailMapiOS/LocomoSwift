//
//  RealtimeManager.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation
import LocomoSwiftGTFS
import SwiftProtobuf

/// GTFS Realtime feed manager with built-in caching.
///
/// Uses an actor to guarantee thread-safe cache access.
/// Cache TTL is driven by each ``DataSource/realtimeCacheTTL``.
public actor RealtimeManager: RealtimeDataSource {

    private let urlSession: URLSession
    private var cache: [String: CachedFeedData] = [:]

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - RealtimeDataSource

    public func fetchTripUpdates(from source: DataSource = .sncf) async throws -> [RealtimeTripUpdate] {
        let url = try source.url(for: .tripUpdates)
        let feedMessage = try await fetchFeedMessage(from: url, cacheKey: "\(source.identifier)_trip_updates", ttl: source.realtimeCacheTTL)
        return TripUpdateMapper.mapTripUpdates(from: feedMessage)
    }

    public func fetchVehiclePositions(from source: DataSource = .sncf) async throws -> [RealtimeVehiclePosition] {
        let url = try source.url(for: .vehiclePositions)
        let feedMessage = try await fetchFeedMessage(from: url, cacheKey: "\(source.identifier)_vehicle_positions", ttl: source.realtimeCacheTTL)
        return VehiclePositionMapper.mapVehiclePositions(from: feedMessage)
    }

    public func fetchServiceAlerts(from source: DataSource = .sncf) async throws -> [RealtimeServiceAlert] {
        let url = try source.url(for: .serviceAlerts)
        let feedMessage = try await fetchFeedMessage(from: url, cacheKey: "\(source.identifier)_service_alerts", ttl: source.realtimeCacheTTL)
        return ServiceAlertMapper.mapServiceAlerts(from: feedMessage)
    }

    public func clearCache() {
        cache.removeAll(keepingCapacity: true)
    }

    // MARK: - Private

    private func fetchFeedMessage(from url: URL, cacheKey: String, ttl: TimeInterval) async throws -> TransitRealtime_FeedMessage {
        if let cachedData = cache[cacheKey], Date().timeIntervalSince(cachedData.timestamp) < ttl {
            return cachedData.feedMessage
        }

        let (data, response) = try await urlSession.data(from: url)

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else { throw RealtimeError.networkError }

        let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)

        cache[cacheKey] = CachedFeedData(
            feedMessage: feedMessage,
            timestamp: Date()
        )

        return feedMessage
    }
}

// MARK: - Internal cache type

private struct CachedFeedData {
    let feedMessage: TransitRealtime_FeedMessage
    let timestamp: Date
}
