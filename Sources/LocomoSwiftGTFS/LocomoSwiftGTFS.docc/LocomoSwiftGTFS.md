# ``LocomoSwiftGTFS``

Parse GTFS Static feeds from ZIP archives or local directories, and configure transit data sources.

## Overview

**LocomoSwiftGTFS** provides everything you need to load and work with GTFS Static data:

- Download and extract GTFS ZIP feeds from remote URLs
- Parse standard GTFS files (`agency.txt`, `routes.txt`, `stops.txt`, `trips.txt`, `stop_times.txt`, `calendar_dates.txt`)
- Configure data sources with ``DataSource`` presets or custom endpoints
- Manage static feed refresh intervals and realtime cache TTLs

```swift
import LocomoSwiftGTFS

// Load from a preset
let feed = try await Feed(from: .sncf)

// Load from a custom URL
let url = URL(string: "https://example.com/gtfs.zip")!
let feed = try await Feed(contentsOfURL: url)
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:DataSourceConfiguration>

### Loading Feeds

- ``Feed``
- ``LSError``

### Data Source Configuration

- ``DataSource``
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
