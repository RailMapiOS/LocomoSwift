# ``LocomoSwiftRT``

Fetch and cache GTFS Realtime data: trip updates, vehicle positions, and service alerts.

## Overview

**LocomoSwiftRT** provides a thread-safe, actor-based manager for consuming GTFS Realtime feeds. It handles protobuf deserialization, in-memory caching, automatic cache expiration based on each data source's TTL, and API key authentication.

```swift
import LocomoSwiftRT

let manager = RealtimeManager()

// Fetch trip updates from SNCF TER
let updates = try await manager.fetchTripUpdates(from: .sncfTER)

// Fetch service alerts
let alerts = try await manager.fetchServiceAlerts(from: .sncfTER)

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
