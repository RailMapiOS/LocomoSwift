# Fetching Realtime Data

Use RealtimeManager to fetch, cache, and consume GTFS Realtime feeds.

## Overview

GTFS Realtime feeds provide live transit information encoded as Protocol Buffer (protobuf) messages. ``RealtimeManager`` handles downloading, deserializing, and caching these feeds so you can focus on using the data.

## Creating a Manager

```swift
import LocomoSwiftRT

let manager = RealtimeManager()
```

You can also provide a custom `URLSession` for advanced networking needs:

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 10
let session = URLSession(configuration: config)
let manager = RealtimeManager(urlSession: session)
```

## Fetching Trip Updates

Trip updates contain delay information for individual stops along a trip:

```swift
let updates = try await manager.fetchTripUpdates(from: .sncfTER)

for update in updates {
    print("Trip \(update.tripID)")
    print("  Route: \(update.routeID ?? "unknown")")
    print("  Start date: \(update.startDate ?? "unknown")")

    for stopUpdate in update.stopTimeUpdates {
        if let delay = stopUpdate.arrivalDelay, delay > 0 {
            print("  Stop \(stopUpdate.stopID ?? "?"): +\(delay)s late")
        }
    }
}
```

## Fetching Vehicle Positions

Vehicle positions provide the current GPS location of transit vehicles:

```swift
let positions = try await manager.fetchVehiclePositions(from: .tamMontpellier)

for position in positions {
    print("Vehicle \(position.vehicleID ?? "unknown")")
    print("  Location: \(position.latitude), \(position.longitude)")
    print("  Speed: \(position.speed ?? 0) m/s")
}
```

> Note: Not all data sources provide vehicle position feeds. Check ``DataSource/availableRealtimeFeedTypes`` before fetching.

## Fetching Service Alerts

Service alerts notify passengers about disruptions, detours, or other service changes:

```swift
let alerts = try await manager.fetchServiceAlerts(from: .sncfTER)

for alert in alerts {
    print("Alert: \(alert.headerText ?? "No title")")
    print("  \(alert.descriptionText ?? "")")

    if let cause = alert.cause {
        print("  Cause: \(cause)")
    }

    for entity in alert.informedEntities {
        if let routeID = entity.routeID {
            print("  Affects route: \(routeID)")
        }
    }
}
```

## Using Sources with API Keys

Some providers require authentication. Use ``DataSource/withAuthentication(_:)`` to inject your API key:

```swift
let mySBB = DataSource.sbb.withAuthentication(
    .queryParam(name: "api_key", value: "YOUR_KEY")
)
let updates = try await manager.fetchTripUpdates(from: mySBB)
```

Authentication is applied automatically to all network requests — both query parameters and HTTP headers are handled transparently.

## Caching Behavior

``RealtimeManager`` automatically caches feed responses in memory. The cache TTL is controlled by each ``DataSource/realtimeCacheTTL``:

- **SNCF (TER, TGV, Intercités)**: 120 seconds (2 minutes)
- **TaM Montpellier**: 60 seconds (1 minute)
- **SBB**: 30 seconds
- **Custom sources**: configurable via the `realtimeCacheTTL` parameter

Subsequent calls within the TTL window return cached data instantly without a network request.

To force a fresh fetch, clear the cache first:

```swift
await manager.clearCache()
let freshUpdates = try await manager.fetchTripUpdates(from: .sncfTER)
```

## Applying Updates to a Feed

You can combine static and realtime data by applying updates to a ``Feed``:

```swift
import LocomoSwift

var feed = try await Feed(from: .sncfTER)
let manager = feed.createRealtimeManager()

let updates = try await manager.fetchTripUpdates(from: .sncfTER)
let alerts = try await manager.fetchServiceAlerts(from: .sncfTER)

feed.applyRealtimeUpdates(
    tripUpdates: updates,
    serviceAlerts: alerts
)
```

## Error Handling

All fetch methods throw ``RealtimeError`` on failure:

```swift
do {
    let updates = try await manager.fetchTripUpdates(from: mySource)
} catch RealtimeError.feedTypeNotAvailable(let type) {
    print("Feed type \(type) is not configured for this source")
} catch RealtimeError.networkError {
    print("Network request failed")
} catch RealtimeError.parsingError {
    print("Failed to parse protobuf response")
}
```

## Using a Custom Data Source

See <doc:DataSourceConfiguration> for creating custom ``DataSource`` instances with your own realtime feed URLs.
