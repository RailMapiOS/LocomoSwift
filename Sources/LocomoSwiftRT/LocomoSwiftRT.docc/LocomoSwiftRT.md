# ``LocomoSwiftRT``

Fetch, decode, and cache GTFS Realtime data — trip updates, vehicle positions, service alerts, realtime shapes — with full coverage of the GTFS-RT v2.0 schema.

## Overview

**LocomoSwiftRT** provides a thread-safe, actor-based manager for consuming GTFS Realtime feeds. It handles protobuf deserialization, in-memory caching with per-source TTL, API key authentication, and exposes the full GTFS-RT schema as idiomatic Swift types — including multi-carriage occupancy, congestion, severity levels, translated strings, and DUPLICATED/REPLACEMENT trip properties.

```swift
import LocomoSwiftRT

let manager = RealtimeManager()

// Convenience: fetch a single entity kind
let updates = try await manager.fetchTripUpdates(from: .sncfTER)
let alerts  = try await manager.fetchServiceAlerts(from: .sncfTER)
let cars    = try await manager.fetchVehiclePositions(from: .tamMontpellier)

// Or grab the entire RealtimeFeed at once (header + every entity)
let feed = try await manager.fetchFeed(from: .sncfTER, feedType: .tripUpdates)
print("Feed v\(feed.header.gtfsRealtimeVersion), \(feed.tripUpdates.count) trip updates")
```

Results are automatically cached per `(DataSource, RealtimeFeedType)`. Subsequent calls within the cache TTL return cached data without making a network request.

## Topics

### Essentials

- <doc:FetchingRealtimeData>

### Fetching Data

- ``RealtimeManager``
- ``RealtimeDataSource``
- ``TripUpdateFetching``
- ``VehiclePositionFetching``
- ``ServiceAlertFetching``
- ``RealtimeFeedFetching``

### Decoding (DIP)

- ``FeedMessageDecoding``
- ``ProtobufFeedMessageDecoder``

### Whole Feed

- ``RealtimeFeed``
- ``RealtimeFeedHeader``
- ``Incrementality``

### Trip Updates

- ``RealtimeTripUpdate``
- ``RealtimeStopTimeUpdate``
- ``RealtimeStopTimeEvent``
- ``RealtimeStopTimeProperties``
- ``RealtimeTripProperties``
- ``TripScheduleRelationship``
- ``StopTimeScheduleRelationship``
- ``DropOffPickupType``

### Vehicle Positions

- ``RealtimeVehiclePosition``
- ``CarriageDetails``
- ``VehicleStopStatus``
- ``CongestionLevel``
- ``OccupancyStatus``

### Service Alerts

- ``RealtimeServiceAlert``
- ``AlertCause``
- ``AlertEffect``
- ``AlertSeverityLevel``
- ``AlertActivePeriod``
- ``AlertInformedEntity``

### Trip & Vehicle Identification

- ``RealtimeTripDescriptor``
- ``RealtimeVehicleDescriptor``
- ``WheelchairAccessible``

### Translated Content

- ``TranslatedString``
- ``TranslatedImage``

### Realtime Shapes

- ``RealtimeShape``

### Feed Integration

- ``TripRealtimeStatus``
