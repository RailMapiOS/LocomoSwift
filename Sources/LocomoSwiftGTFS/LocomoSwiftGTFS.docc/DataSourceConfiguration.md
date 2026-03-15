# Configuring Data Sources

Use built-in presets or create custom data sources for any transit provider, with optional API key authentication.

## Overview

The ``DataSource`` struct is the central configuration type in LocomoSwift. It holds everything needed to access both GTFS Static and GTFS Realtime feeds from a transit provider: URLs, refresh intervals, cache settings, and authentication credentials.

## Using Presets

LocomoSwift ships with presets for common European transit networks:

```swift
// SNCF TER — Regional Express Trains
// Static feed refreshed daily, RT cache TTL of 120 seconds
let feed = try await Feed(from: .sncfTER)

// TaM Montpellier — Tramway and bus
// Static feed refreshed weekly, RT cache TTL of 60 seconds
let feed = try await Feed(from: .tamMontpellier)
```

Available presets: `.sncfTER`, `.sncfTGV`, `.sncfIntercites`, `.breizhgoTER`, `.tamMontpellier`, `.sbb`.

## Creating a Custom DataSource

For any transit provider that publishes GTFS data, create a custom ``DataSource``:

```swift
let mySource = DataSource(
    identifier: "flixbus-de",
    displayName: "FlixBus Germany",
    staticFeedURL: URL(string: "https://example.com/gtfs.zip"),
    staticRefreshInterval: 86_400,    // 24 hours
    realtimeFeeds: [
        .tripUpdates: URL(string: "https://example.com/trip-updates.pb")!,
        .vehiclePositions: URL(string: "https://example.com/positions.pb")!,
        .serviceAlerts: URL(string: "https://example.com/alerts.pb")!,
    ],
    realtimeCacheTTL: 30              // 30 seconds
)
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `identifier` | `String` | Required | Unique key for caching and logging |
| `displayName` | `String` | Required | Human-readable name |
| `authentication` | ``APIAuthentication`` | `.none` | API key or token configuration |
| `staticFeedURL` | `URL?` | `nil` | URL of the GTFS Static ZIP archive |
| `staticRefreshInterval` | `TimeInterval` | `86400` (24h) | How often the static feed is republished |
| `realtimeFeeds` | `[RealtimeFeedType: URL]` | `[:]` | Realtime feed URLs by type |
| `realtimeCacheTTL` | `TimeInterval` | `120` | Cache duration for realtime data |

## API Key Authentication

Many providers require an API key. LocomoSwift supports two authentication methods via ``APIAuthentication``:

### Query Parameter

Appends a query parameter to every request URL:

```swift
let source = DataSource(
    identifier: "swiss-rt",
    displayName: "Swiss Realtime",
    authentication: .queryParam(name: "api_key", value: "YOUR_KEY"),
    realtimeFeeds: [
        .tripUpdates: URL(string: "https://api.opentransportdata.swiss/gtfsrt2020")!,
    ]
)
```

### HTTP Header

Adds a custom header to every request:

```swift
let source = DataSource(
    identifier: "my-provider",
    displayName: "My Provider",
    authentication: .header(name: "Authorization", value: "Bearer YOUR_TOKEN"),
    realtimeFeeds: [
        .tripUpdates: URL(string: "https://api.example.com/trip-updates.pb")!,
    ]
)
```

### Injecting Auth into a Preset

Use ``DataSource/withAuthentication(_:)`` to add credentials to an existing preset without reconfiguring URLs:

```swift
let mySBB = DataSource.sbb.withAuthentication(
    .queryParam(name: "api_key", value: "YOUR_KEY")
)
let updates = try await manager.fetchTripUpdates(from: mySBB)
```

## Static-Only Sources

If your provider only offers static GTFS data, omit the `realtimeFeeds`:

```swift
let staticOnly = DataSource(
    identifier: "my-city-bus",
    displayName: "My City Bus",
    staticFeedURL: URL(string: "https://example.com/gtfs.zip"),
    staticRefreshInterval: 604_800  // 7 days
)
```

## Realtime-Only Sources

If you only need realtime data (e.g., trip updates from a known provider), omit `staticFeedURL`:

```swift
let realtimeOnly = DataSource(
    identifier: "my-alerts",
    displayName: "Alert Service",
    realtimeFeeds: [
        .serviceAlerts: URL(string: "https://example.com/alerts.pb")!,
    ],
    realtimeCacheTTL: 60
)
```

## Checking Feed Availability

```swift
let source = DataSource.sncfTER

// Check if static feed is available
if source.hasStaticFeed {
    let feed = try await Feed(from: source)
}

// Check available realtime feed types
print(source.availableRealtimeFeedTypes) // [.tripUpdates, .serviceAlerts]

// Get a specific realtime URL (throws if not available)
let url = try source.url(for: .tripUpdates)
```

## Managing Refresh Intervals

The ``DataSource/staticFeedNeedsRefresh(since:)`` method helps determine if cached static data is stale:

```swift
let lastFetchDate = Date(timeIntervalSinceNow: -90_000) // 25 hours ago
if DataSource.sncfTER.staticFeedNeedsRefresh(since: lastFetchDate) {
    // Time to re-download the static feed
    let feed = try await Feed(from: .sncfTER)
}
```
