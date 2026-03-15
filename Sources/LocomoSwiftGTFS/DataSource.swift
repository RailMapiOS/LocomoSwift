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

// MARK: - APIAuthentication

/// Authentication method used to access a transit data provider's API.
///
/// Many open-data providers require an API key or token to access their
/// GTFS feeds. Use this enum to configure the appropriate authentication
/// strategy for each ``DataSource``.
///
/// ```swift
/// // Swiss open data requires a query parameter
/// let sbb = DataSource(
///     identifier: "sbb",
///     displayName: "SBB/CFF/FFS",
///     authentication: .queryParam(name: "api_key", value: "YOUR_KEY"),
///     ...
/// )
///
/// // Some providers use a Bearer token header
/// let custom = DataSource(
///     identifier: "custom",
///     displayName: "Custom Provider",
///     authentication: .header(name: "Authorization", value: "Bearer YOUR_TOKEN"),
///     ...
/// )
/// ```
public enum APIAuthentication: Sendable {
    /// No authentication required.
    case none

    /// Append a query parameter to every request URL.
    ///
    /// - Parameters:
    ///   - name: The query parameter name (e.g. `"api_key"`).
    ///   - value: The query parameter value.
    case queryParam(name: String, value: String)

    /// Add a custom HTTP header to every request.
    ///
    /// - Parameters:
    ///   - name: The header field name (e.g. `"Authorization"`, `"X-API-Key"`).
    ///   - value: The header field value.
    case header(name: String, value: String)

    /// Apply authentication to a URL by appending a query parameter if needed.
    ///
    /// Returns the original URL unchanged for `.none` and `.header`.
    public func authenticatedURL(_ url: URL) -> URL {
        switch self {
        case .none, .header:
            return url
        case .queryParam(let name, let value):
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return url
            }
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: name, value: value))
            components.queryItems = items
            return components.url ?? url
        }
    }

    /// Apply authentication to a URLRequest by adding headers if needed.
    ///
    /// Query-param authentication is handled at the URL level, so this
    /// method only modifies the request for `.header` authentication.
    public func authenticatedRequest(_ request: URLRequest) -> URLRequest {
        switch self {
        case .none, .queryParam:
            return request
        case .header(let name, let value):
            var req = request
            req.setValue(value, forHTTPHeaderField: name)
            return req
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
/// // Source with API key authentication
/// let sbb = DataSource(
///     identifier: "sbb",
///     displayName: "SBB/CFF/FFS",
///     authentication: .queryParam(name: "api_key", value: "YOUR_KEY"),
///     staticFeedURL: URL(string: "https://opentransportdata.swiss/gtfs.zip")!,
///     realtimeFeeds: [
///         .tripUpdates: URL(string: "https://api.opentransportdata.swiss/gtfs-rt")!,
///     ],
///     realtimeCacheTTL: 30
/// )
/// ```
public struct DataSource: Sendable {

    /// Unique identifier used for caching and logging.
    public let identifier: String

    /// Human-readable name for display purposes.
    public let displayName: String

    // MARK: Authentication

    /// Authentication method for API requests (static and realtime).
    ///
    /// Defaults to `.none`. Set this to `.queryParam` or `.header`
    /// when the provider requires an API key or token.
    public let authentication: APIAuthentication

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
        authentication: APIAuthentication = .none,
        staticFeedURL: URL? = nil,
        staticRefreshInterval: TimeInterval = 86400,
        realtimeFeeds: [RealtimeFeedType: URL] = [:],
        realtimeCacheTTL: TimeInterval = 120
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.authentication = authentication
        self.staticFeedURL = staticFeedURL
        self.staticRefreshInterval = staticRefreshInterval
        self.realtimeFeeds = realtimeFeeds
        self.realtimeCacheTTL = realtimeCacheTTL
    }

    /// Returns the raw (unauthenticated) Realtime URL for the given feed type.
    ///
    /// Use ``authenticatedRequest(for:)`` or ``authenticatedRealtimeRequest(for:)``
    /// to build a fully authenticated request.
    ///
    /// - Throws: ``RealtimeError/feedTypeNotAvailable(_:)`` if the feed is not configured.
    public func url(for feedType: RealtimeFeedType) throws -> URL {
        guard let url = realtimeFeeds[feedType] else {
            throw RealtimeError.feedTypeNotAvailable(feedType)
        }
        return url
    }

    /// Returns a fully authenticated `URLRequest` for the given realtime feed type.
    ///
    /// Convenience combining ``url(for:)`` and ``authenticatedRequest(for:)``.
    ///
    /// - Throws: ``RealtimeError/feedTypeNotAvailable(_:)`` if the feed is not configured.
    public func authenticatedRealtimeRequest(for feedType: RealtimeFeedType) throws -> URLRequest {
        let url = try url(for: feedType)
        return authenticatedRequest(for: url)
    }

    /// Returns the authenticated static feed URL, if configured.
    ///
    /// - Throws: ``RealtimeError/staticFeedNotConfigured(_:)`` if no static URL is set.
    public func authenticatedStaticFeedURL() throws -> URL {
        guard let url = staticFeedURL else {
            throw RealtimeError.staticFeedNotConfigured(identifier)
        }
        return authentication.authenticatedURL(url)
    }

    /// Creates an authenticated `URLRequest` for the given URL.
    ///
    /// Applies both URL-level (query param) and request-level (header)
    /// authentication in one step.
    public func authenticatedRequest(for url: URL) -> URLRequest {
        let authenticatedURL = authentication.authenticatedURL(url)
        let request = URLRequest(url: authenticatedURL)
        return authentication.authenticatedRequest(request)
    }

    /// Returns a copy of this data source with the given authentication applied.
    ///
    /// Useful for presets that define URLs but require the user to supply
    /// their own API key at runtime.
    ///
    /// ```swift
    /// let mySBB = DataSource.sbb.withAuthentication(
    ///     .queryParam(name: "api_key", value: "YOUR_KEY")
    /// )
    /// let updates = try await manager.fetchTripUpdates(from: mySBB)
    /// ```
    public func withAuthentication(_ auth: APIAuthentication) -> DataSource {
        DataSource(
            identifier: identifier,
            displayName: displayName,
            authentication: auth,
            staticFeedURL: staticFeedURL,
            staticRefreshInterval: staticRefreshInterval,
            realtimeFeeds: realtimeFeeds,
            realtimeCacheTTL: realtimeCacheTTL
        )
    }
}

// MARK: - DataSource Presets

extension DataSource {
    
    /// SNCF TER — Regional Express Trains
    public static let sncfTER = DataSource(
        identifier: "sncf-ter",
        displayName: "SNCF TER",
        staticFeedURL: URL(string: "https://eu.ftp.opendatasoft.com/sncf/plandata/Export_OpenData_SNCF_GTFS_NewTripId.zip"),
        staticRefreshInterval: 86_400, // 24h
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-trip-updates")!,
            .serviceAlerts: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-service-alerts")!,
        ],
        realtimeCacheTTL: 120
    )
    
    /// SNCF TGV — High-speed long-distance trains
    public static let sncfTGV = DataSource(
        identifier: "sncf-tgv",
        displayName: "SNCF TGV",
        staticFeedURL: URL(string: "https://eu.ftp.opendatasoft.com/sncf/plandata/Export_OpenData_SNCF_GTFS_NewTripId.zip"),
        staticRefreshInterval: 86_400, // 24h
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-trip-updates")!,
            .serviceAlerts: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-service-alerts")!,
        ],
        realtimeCacheTTL: 120
    )
    
    /// SNCF Intercités
    public static let sncfIntercites = DataSource(
        identifier: "sncf-intercites",
        displayName: "SNCF Intercités",
        staticFeedURL: URL(string: "https://eu.ftp.opendatasoft.com/sncf/plandata/Export_OpenData_SNCF_GTFS_NewTripId.zip"),
        staticRefreshInterval: 86_400, // 24h
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-trip-updates")!,
            .serviceAlerts: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-service-alerts")!,
        ],
        realtimeCacheTTL: 120
    )
    
    /// Breizhgo TER
    public static let breizhgoTER = DataSource(
        identifier: "breizhgo-ter",
        displayName: "Breizhgo TER",
        staticFeedURL: URL(string: "https://www.korrigo.bzh/ftp/OPENDATA/BREIZHGO_TER.gtfs.zip"),
        staticRefreshInterval: 86_400, // 24h
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-trip-updates")!,
            .serviceAlerts: URL(string: "https://proxy.transport.data.gouv.fr/resource/sncf-gtfs-rt-service-alerts")!,
        ],
        realtimeCacheTTL: 120
    )
    
    /// SBB/CFF/FFS — Swiss Federal Railways.
    ///
    /// **Requires an API key.** Register at
    /// [opentransportdata.swiss](https://opentransportdata.swiss) to obtain one,
    /// then use ``withAuthentication(_:)`` to inject it:
    ///
    /// ```swift
    /// let mySBB = DataSource.sbb.withAuthentication(
    ///     .queryParam(name: "api_key", value: "YOUR_KEY")
    /// )
    /// ```
    public static let sbb = DataSource(
        identifier: "sbb",
        displayName: "SBB/CFF/FFS",
        staticFeedURL: URL(string: "https://opentransportdata.swiss/en/dataset/timetable-2025-gtfs2020/permalink"),
        staticRefreshInterval: 15_778_463, // ~6 months
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://api.opentransportdata.swiss/gtfsrt2020")!,
            .serviceAlerts: URL(string: "https://api.opentransportdata.swiss/gtfs-sa")!,
        ],
        realtimeCacheTTL: 30
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
