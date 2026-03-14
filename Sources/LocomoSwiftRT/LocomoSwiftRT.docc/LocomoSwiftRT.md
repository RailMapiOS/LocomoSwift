# ``LocomoSwiftRT``

Fetch and cache GTFS Realtime data: trip updates, vehicle positions, and service alerts.

## Overview

**LocomoSwiftRT** provides a thread-safe, actor-based manager for consuming GTFS Realtime feeds. It handles protobuf deserialization, in-memory caching, and automatic cache expiration based on each data source's TTL configuration.

```swift
import LocomoSwiftRT

let manager = RealtimeManager()

// Fetch trip updates from SNCF
let updates = try await manager.fetchTripUpdates(from: .sncf)

// Fetch service alerts
let alerts = try await manager.fetchServiceAlerts(from: .sncf)

// Fetch vehicle positions (from sources that support it)
let positions = try await manager.fetchVehiclePositions(from: .tamMontpellier)
```

Results are automatically cached. Subsequent calls within the cache TTL return cached data without making a network request.

## Topics

### Essentials

- <doc:FetchingRealtimeData>

### Fetching Data

- ``RealtimeManager``
- ``RealtimeDataSource``

### Trip Updates

- ``RealtimeTripUpdate``
- ``RealtimeStopTimeUpdate``
- ``RealtimeScheduleRelationship``
- ``RealtimeStopScheduleRelationship``

### Vehicle Positions

- ``RealtimeVehiclePosition``
- ``RealtimeCongestionLevel``
- ``RealtimeOccupancyStatus``

### Service Alerts

- ``RealtimeServiceAlert``
- ``AlertCause``
- ``AlertEffect``
- ``AlertActivePeriod``
- ``AlertInformedEntity``

### Feed Integration

- ``TripRealtimeStatus``
