//
//  DataSource.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation

// MARK: - RealtimeFeedType

/// The type of GTFS Realtime feed available.
public enum RealtimeFeedType: Sendable, Hashable, CustomStringConvertible {
    case tripUpdates
    case vehiclePositions
    case serviceAlerts

    public var description: String {
        switch self {
        case .tripUpdates: "tripUpdates"
        case .vehiclePositions: "vehiclePositions"
        case .serviceAlerts: "serviceAlerts"
        }
    }
}

// MARK: - DataSource

/// Complete configuration for a transit data source.
///
/// Combines GTFS Static (ZIP) and GTFS Realtime (protobuf) configuration
/// into a single entry point. Use the built-in presets or create a custom
/// source to inject your own endpoints.
///
/// ```swift
/// // Load static + RT data from a preset
/// var feed = try await Feed(from: .sncf)
/// let updates = try await manager.fetchTripUpdates(from: .sncf)
///
/// // Fully custom source
/// let mySource = DataSource(
///     identifier: "flixbus-de",
///     displayName: "FlixBus Germany",
///     staticFeedURL: URL(string: "https://example.com/gtfs.zip")!,
///     realtimeFeeds: [
///         .tripUpdates: URL(string: "https://example.com/trip-updates.pb")!,
///         .serviceAlerts: URL(string: "https://example.com/alerts.pb")!,
///     ],
///     realtimeCacheTTL: 60
/// )
/// ```
public struct DataSource: Sendable {

    /// Unique identifier used for caching and logging.
    public let identifier: String

    /// Human-readable name for display purposes.
    public let displayName: String

    // MARK: GTFS Static

    /// URL of the GTFS static feed (ZIP archive or directory).
    public let staticFeedURL: URL?

    /// Refresh interval for the GTFS static feed.
    ///
    /// Indicates how often the ZIP is republished by the producer.
    /// Example: SNCF = 24h (daily refresh at ~5 AM), Swiss SBB = 365 days.
    public let staticRefreshInterval: TimeInterval

    // MARK: GTFS Realtime

    /// URLs of GTFS Realtime feeds indexed by feed type.
    public let realtimeFeeds: [RealtimeFeedType: URL]

    /// Time-to-live for the Realtime cache, in seconds.
    public let realtimeCacheTTL: TimeInterval

    /// Whether this source provides static GTFS data.
    public var hasStaticFeed: Bool { staticFeedURL != nil }

    /// The set of Realtime feed types available for this source.
    public var availableRealtimeFeedTypes: Set<RealtimeFeedType> {
        Set(realtimeFeeds.keys)
    }

    /// Returns whether the static feed should be refreshed since a given date.
    public func staticFeedNeedsRefresh(since lastFetch: Date) -> Bool {
        Date().timeIntervalSince(lastFetch) >= staticRefreshInterval
    }

    public init(
        identifier: String,
        displayName: String,
        staticFeedURL: URL? = nil,
        staticRefreshInterval: TimeInterval = 86400,
        realtimeFeeds: [RealtimeFeedType: URL] = [:],
        realtimeCacheTTL: TimeInterval = 120
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.staticFeedURL = staticFeedURL
        self.staticRefreshInterval = staticRefreshInterval
        self.realtimeFeeds = realtimeFeeds
        self.realtimeCacheTTL = realtimeCacheTTL
    }

    /// Returns the Realtime URL for the given feed type.
    /// - Throws: ``RealtimeError/feedTypeNotAvailable(_:)`` if the feed is not configured.
    public func url(for feedType: RealtimeFeedType) throws -> URL {
        guard let url = realtimeFeeds[feedType] else {
            throw RealtimeError.feedTypeNotAvailable(feedType)
        }
        return url
    }
}

// MARK: - DataSource Presets

extension DataSource {

    /// SNCF — TER, TGV, Intercités.
    /// Static feed republished daily (~5 AM).
    public static let sncf = DataSource(
        identifier: "sncf",
        displayName: "SNCF",
        staticFeedURL: URL(string: "https://eu.ftp.opendatasoft.com/sncf/gtfs/export-ter-gtfs-last.zip"),
        staticRefreshInterval: 86_400, // 24h
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-trip-updates")!,
            .serviceAlerts: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-service-alerts")!,
        ],
        realtimeCacheTTL: 120
    )

    /// TaM Montpellier — Tramway and bus.
    /// Static feed republished weekly.
    public static let tamMontpellier = DataSource(
        identifier: "tam-montpellier",
        displayName: "TaM Montpellier",
        staticFeedURL: URL(string: "https://data.montpellier3m.fr/GTFS/TAM_MMM_GTFS.zip"),
        staticRefreshInterval: 604_800, // 7 days
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://data.montpellier3m.fr/GTFS/Suburbain/TripUpdate.pb")!,
            .vehiclePositions: URL(string: "https://data.montpellier3m.fr/GTFS/Suburbain/VehiclePosition.pb")!,
            .serviceAlerts: URL(string: "https://data.montpellier3m.fr/GTFS/Urbain/Alert.pb")!,
        ],
        realtimeCacheTTL: 60
    )
}
