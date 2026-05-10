# ``LocomoSwiftGTFS``

Parse GTFS Static feeds from ZIP archives or local directories, and configure transit data sources with optional API key authentication.

## Overview

**LocomoSwiftGTFS** provides everything you need to load and work with GTFS Static data:

- Download and extract GTFS ZIP feeds from remote URLs
- Parse standard GTFS files (`agency.txt`, `routes.txt`, `stops.txt`, `trips.txt`, `stop_times.txt`, `calendar_dates.txt`, `shapes.txt`)
- Configure data sources with ``DataSource`` presets or custom endpoints
- Authenticate with API keys via query parameters or HTTP headers
- Manage static feed refresh intervals and realtime cache TTLs

```swift
import LocomoSwiftGTFS

// Load from a preset
let feed = try await Feed(from: .sncfTER)

// Load from a custom URL
let url = URL(string: "https://example.com/gtfs.zip")!
let feed = try await Feed(contentsOfURL: url)

// Load from a source that requires an API key
let sbb = DataSource.sbb.withAuthentication(
    .queryParam(name: "api_key", value: "YOUR_KEY")
)
let feed = try await Feed(from: sbb)
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:DataSourceConfiguration>
- <doc:Shapes>

### Loading Feeds

- ``Feed``
- ``LSError``

### Data Source Configuration

- ``DataSource``
- ``APIAuthentication``
- ``RealtimeFeedType``
- ``RealtimeError``

### GTFS Models

- ``Agency``
- ``Agencies``
- ``Route``
- ``Routes``
- ``Stop``
- ``Stops``
- ``Trip``
- ``Trips``
- ``StopTime``
- ``StopTimes``
- ``CalendarDate``
- ``CalendarDates``
- ``ShapePoint``
- ``Shapes``

### Cross-Platform Types

- ``LSColor``
