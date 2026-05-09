# Fetching Realtime Data

Use ``RealtimeManager`` to fetch, decode, and cache GTFS Realtime feeds — trip updates, vehicle positions, service alerts, and realtime shapes.

## Overview

GTFS Realtime feeds are delivered as Protocol Buffer (protobuf) messages. ``RealtimeManager`` handles downloading, deserializing, and caching them so you can consume idiomatic Swift values directly. Caching is keyed by `(DataSource.identifier, RealtimeFeedType)` and respects each source's ``DataSource/realtimeCacheTTL``.

## Creating a Manager

```swift
import LocomoSwiftRT

let manager = RealtimeManager()
```

The manager accepts a custom `URLSession` and a custom decoder (Dependency Inversion):

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 10
let session = URLSession(configuration: config)

let manager = RealtimeManager(
    urlSession: session,
    decoder: ProtobufFeedMessageDecoder() // or your own ``FeedMessageDecoding``
)
```

## Fetching the Whole Feed

``RealtimeManager/fetchFeed(from:feedType:)`` returns a ``RealtimeFeed`` containing the header plus every entity kind contained in the message — handy when you want all the data in one round-trip:

```swift
let feed = try await manager.fetchFeed(from: .sncfTER, feedType: .tripUpdates)

print("GTFS-RT \(feed.header.gtfsRealtimeVersion), generated at \(feed.header.timestamp ?? .now)")
print("\(feed.tripUpdates.count) trip updates, \(feed.serviceAlerts.count) alerts")

if feed.header.incrementality == .differential {
    print("Deleted entities: \(feed.deletedEntityIDs)")
}
```

## Fetching Trip Updates

```swift
let updates = try await manager.fetchTripUpdates(from: .sncfTER)

for update in updates {
    let id = update.trip.tripID ?? "?"
    print("Trip \(id) (route \(update.trip.routeID ?? "?"))")
    if let delay = update.delay {
        print("  Trip-level delay: \(delay)s")
    }
    if let vehicle = update.vehicle {
        print("  Operated by vehicle \(vehicle.id ?? "?") — \(vehicle.label ?? "")")
    }

    for stopUpdate in update.stopTimeUpdates {
        if let stop = stopUpdate.stopID, let delay = stopUpdate.arrivalDelay, delay > 0 {
            print("  Stop \(stop): +\(delay)s late")
        }
    }
}
```

### DUPLICATED / REPLACEMENT Trips

When a producer adds an extra trip on top of the schedule, the trip's ``RealtimeTripUpdate/trip`` carries `scheduleRelationship == .duplicated` (or `.new`, `.replacement`) and the details land in ``RealtimeTripUpdate/tripProperties``:

```swift
if update.trip.scheduleRelationship == .duplicated,
   let properties = update.tripProperties {
    print("Duplicate of \(properties.tripID ?? "?")")
    print("  Starts at \(properties.startTime ?? "?") on \(properties.startDate ?? "?")")
    print("  Detour shape: \(properties.shapeID ?? "(none)")")
}
```

### Stop Reassignments and Skipped Stops

``RealtimeStopTimeUpdate`` exposes the per-stop schedule relationship, the optional ``RealtimeStopTimeProperties`` (assigned platform, headsign, pickup/drop-off changes), and the post-departure ``RealtimeStopTimeUpdate/departureOccupancyStatus``:

```swift
for stu in update.stopTimeUpdates where stu.scheduleRelationship == .skipped {
    print("Stop \(stu.stopID ?? "?") will be skipped")
}

if let properties = stu.stopTimeProperties,
   let platform = properties.assignedStopID {
    print("New platform: \(platform)")
}
```

## Fetching Vehicle Positions

```swift
let positions = try await manager.fetchVehiclePositions(from: .tamMontpellier)

for position in positions {
    print("Vehicle \(position.vehicle.id ?? "?") (\(position.vehicle.label ?? ""))")

    if let lat = position.latitude, let lon = position.longitude {
        print("  Location: \(lat), \(lon)")
    }
    if let speed = position.speed {
        print("  Speed: \(speed) m/s")
    }
    print("  Status: \(position.currentStatus)")

    if let congestion = position.congestionLevel {
        print("  Traffic congestion: \(congestion)")
    }
    if let pct = position.occupancyPercentage {
        print("  Onboard occupancy: \(pct)%")
    }
}
```

> Note: not every data source provides vehicle positions. Inspect ``DataSource/availableRealtimeFeedTypes`` first.

### Multi-Carriage Trains

Long-distance trains often emit per-carriage occupancy (TGV duplex, Eurostar e320, ICE…). LocomoSwiftRT exposes them via ``RealtimeVehiclePosition/multiCarriageDetails``:

```swift
for position in positions where !position.multiCarriageDetails.isEmpty {
    for car in position.multiCarriageDetails.sorted(by: { $0.carriageSequence < $1.carriageSequence }) {
        let label = car.label ?? "Car \(car.carriageSequence)"
        let pct = car.occupancyPercentage.map { "\($0)%" } ?? "—"
        let status = car.occupancyStatus.map { "\($0)" } ?? "no data"
        print("\(label): \(status) (\(pct))")
    }
}
```

## Fetching Service Alerts

Alert text fields are `TranslatedString` values — pick the right language with ``TranslatedString/text(for:)``:

```swift
let alerts = try await manager.fetchServiceAlerts(from: .sncfTER)

for alert in alerts where alert.isActive() {
    let title = alert.headerText?.text(for: .current) ?? "Untitled"
    let body = alert.descriptionText?.text(for: .current) ?? ""
    print("[\(alert.severityLevel ?? .unknown)] \(title)")
    print("  \(body)")

    if let cause = alert.cause {
        print("  Cause: \(cause)")
    }
    if let detail = alert.causeDetail?.text(for: .current) {
        print("  Detail: \(detail)")
    }
}
```

### Inspecting Affected Entities

``AlertInformedEntity/trip`` is a full ``RealtimeTripDescriptor`` (not just a tripID) — useful to filter by route, direction, or origin date:

```swift
for alert in alerts {
    for entity in alert.informedEntities {
        if let routeID = entity.routeID {
            print("Affects route \(routeID), direction \(entity.directionID.map { "\($0)" } ?? "any")")
        }
        if let trip = entity.trip {
            print("  Specifically trip \(trip.tripID ?? "?") on \(trip.startDate ?? "any date")")
        }
    }
}
```

### Translated Images

If the producer attached a graphic (signage, accessibility map…), ``RealtimeServiceAlert/image`` exposes a ``TranslatedImage``:

```swift
if let localized = alert.image?.image(for: .current) {
    // localized.url, localized.mediaType, localized.language
}
```

### Text-to-Speech Variants

For voice-readout pipelines, prefer ``RealtimeServiceAlert/ttsHeaderText`` and ``RealtimeServiceAlert/ttsDescriptionText`` when the producer provides them — they're sanitized for TTS engines (no emoji, expanded abbreviations, etc.):

```swift
let voiceText = alert.ttsHeaderText?.text(for: .current)
                ?? alert.headerText?.text(for: .current)
                ?? ""
```

## Authentication

Inject your API key once at the ``DataSource`` level — both static feed downloads and realtime fetches will pick it up automatically:

```swift
let mySBB = DataSource.sbb.withAuthentication(
    .queryParam(name: "api_key", value: "YOUR_KEY")
)
let updates = try await manager.fetchTripUpdates(from: mySBB)
```

## Caching Behavior

``RealtimeManager`` caches per `(DataSource.identifier, feedType)` with the source's TTL:

- **SNCF (TER, TGV, Intercités)**: 120 seconds
- **TaM Montpellier**: 60 seconds
- **SBB**: 30 seconds
- **Custom sources**: configurable via the `realtimeCacheTTL` parameter

Force a fresh fetch by clearing the cache:

```swift
await manager.clearCache()
let fresh = try await manager.fetchTripUpdates(from: .sncfTER)
```

## Custom Decoder

Replace the protobuf decoder for testing, fixture playback, or alternative wire formats by providing your own ``FeedMessageDecoding``:

```swift
struct FixturePlayback: FeedMessageDecoding {
    let canned: RealtimeFeed
    func decode(_ data: Data) throws -> RealtimeFeed { canned }
}

let manager = RealtimeManager(decoder: FixturePlayback(canned: myFixtureFeed))
```

## Error Handling

All fetch methods throw ``RealtimeError``:

```swift
do {
    let updates = try await manager.fetchTripUpdates(from: mySource)
} catch RealtimeError.feedTypeNotAvailable(let type) {
    print("Feed type \(type) is not configured for this source")
} catch RealtimeError.networkError {
    print("Network request failed (or upstream returned non-200)")
} catch RealtimeError.parsingError {
    print("Failed to parse the protobuf payload")
}
```

## Custom Data Sources

See <doc:DataSourceConfiguration> in the **LocomoSwiftGTFS** catalogue for creating custom ``DataSource`` instances.
