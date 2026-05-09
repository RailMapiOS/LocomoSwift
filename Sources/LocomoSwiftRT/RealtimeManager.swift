//
//  RealtimeManager.swift
//  LocomoSwift
//
//  GTFS Realtime feed manager with built-in caching.
//
//  Caching is keyed by `(DataSource.identifier, RealtimeFeedType)` and
//  invalidated based on each source's `realtimeCacheTTL`. Decoding is
//  delegated to a `FeedMessageDecoding` so consumers can plug in custom
//  pipelines (alternative formats, compression, fixtures…).
//

import Foundation
import LocomoSwiftGTFS

public actor RealtimeManager: RealtimeDataSource {

    private let urlSession: URLSession
    private let decoder: FeedMessageDecoding
    private var cache: [CacheKey: CachedEntry] = [:]

    public init(
        urlSession: URLSession = .shared,
        decoder: FeedMessageDecoding = ProtobufFeedMessageDecoder()
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
    }

    // MARK: - Per-feed convenience

    public func fetchTripUpdates(from source: DataSource) async throws -> [RealtimeTripUpdate] {
        try await fetchFeed(from: source, feedType: .tripUpdates).tripUpdates
    }

    public func fetchVehiclePositions(from source: DataSource) async throws -> [RealtimeVehiclePosition] {
        try await fetchFeed(from: source, feedType: .vehiclePositions).vehiclePositions
    }

    public func fetchServiceAlerts(from source: DataSource) async throws -> [RealtimeServiceAlert] {
        try await fetchFeed(from: source, feedType: .serviceAlerts).serviceAlerts
    }

    // MARK: - Whole-feed fetch

    /// Fetches and decodes the entire ``RealtimeFeed`` for the given feed type.
    ///
    /// Subsequent calls within the source's ``DataSource/realtimeCacheTTL``
    /// return the cached result without making a network request. Use
    /// ``clearCache()`` to force a fresh fetch.
    public func fetchFeed(from source: DataSource, feedType: RealtimeFeedType) async throws -> RealtimeFeed {
        let key = CacheKey(identifier: source.identifier, feedType: feedType)
        if let entry = cache[key], Date().timeIntervalSince(entry.timestamp) < source.realtimeCacheTTL {
            return entry.feed
        }

        let request = try source.authenticatedRealtimeRequest(for: feedType)
        let (data, response) = try await urlSession.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RealtimeError.networkError
        }

        let feed = try decoder.decode(data)
        cache[key] = CachedEntry(feed: feed, timestamp: Date())
        return feed
    }

    public func clearCache() {
        cache.removeAll(keepingCapacity: true)
    }

    // MARK: - Internal cache key

    private struct CacheKey: Hashable {
        let identifier: String
        let feedType: RealtimeFeedType
    }

    private struct CachedEntry {
        let feed: RealtimeFeed
        let timestamp: Date
    }
}
