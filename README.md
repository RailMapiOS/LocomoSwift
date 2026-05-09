# LocomoSwift

<img src="https://github.com/user-attachments/assets/4a4a8f7a-360f-4b5d-ac4b-c3e9c54cae7d" alt="LocomoSwift Logo" width="150" align="right">

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20|%20macOS%2012%20|%20tvOS%2015%20|%20watchOS%208-blue)
![SPM](https://img.shields.io/badge/SPM-compatible-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A Swift package for parsing **GTFS Static** feeds and consuming **GTFS Realtime** data, with built-in presets for European transit networks and easy extensibility for any provider worldwide.

## Features

- **GTFS Static** — Parse ZIP or folder-based feeds: agencies, routes, stops, trips, stop times, calendar dates, shapes
- **GTFS Realtime** — Fetch trip updates, vehicle positions, and service alerts from protobuf feeds
- **DataSource presets** — Pre-configured sources for SNCF, SBB, TaM Montpellier, and more
- **Custom DataSources** — Inject your own endpoints for any transit provider
- **API key support** — Built-in authentication via query parameters or HTTP headers
- **Actor-based concurrency** — Thread-safe realtime cache via Swift's `actor` model
- **Filesystem-free parsing** — Every collection accepts a CSV string directly, no disk I/O required
- **Concurrent ZIP parsing** — GTFS files inside an archive are decoded in parallel via `async let`
- **Modular imports** — Import only what you need: static, realtime, or both

## Installation

Add LocomoSwift to your project via **Swift Package Manager**.

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RailMapiOS/LocomoSwift.git", from: "1.1.1")
]
```

Then add the desired product to your target:

```swift
// Everything (GTFS Static + Realtime)
.product(name: "LocomoSwift", package: "LocomoSwift")

// GTFS Static only
.product(name: "LocomoSwiftGTFS", package: "LocomoSwift")

// GTFS Realtime only (includes LocomoSwiftGTFS as a dependency)
.product(name: "LocomoSwiftRT", package: "LocomoSwift")
```

## Quick Start

### Load a GTFS Static Feed

```swift
import LocomoSwiftGTFS

// From a preset DataSource
let feed = try await Feed(from: .sncfTER)

// From a custom URL
let url = URL(string: "https://example.com/gtfs.zip")!
let feed = try await Feed(contentsOfURL: url)

// Access transit data
feed.agencies?.forEach { print($0.name) }
feed.routes?.forEach   { print($0.shortName ?? "?") }
feed.stops?.forEach    { print($0.name ?? "Unnamed") }
feed.shapes?.shapeIDs.forEach { print("Shape: \($0)") }
```

### Parse Without the Filesystem

When you already have GTFS data in memory, every collection accepts a CSV string directly:

```swift
import LocomoSwiftGTFS

let csv = """
stop_id,stop_name,stop_lat,stop_lon
S1,Alpha,48.8584,2.2945
S2,Bravo,48.8606,2.3376
"""

let stops = try Stops(from: csv)
```

The same pattern works for `Agencies`, `Routes`, `Trips`, `StopTimes` (also takes a `timeZone:`), `CalendarDates`, and `Shapes`.

### Fetch GTFS Realtime Data

```swift
import LocomoSwiftRT

let manager = RealtimeManager()

// Fetch trip updates
let updates = try await manager.fetchTripUpdates(from: .sncfTER)
for update in updates {
    print("\(update.tripID): delay \(update.stopTimeUpdates.first?.arrivalDelay ?? 0)s")
}

// Fetch vehicle positions
let positions = try await manager.fetchVehiclePositions(from: .tamMontpellier)

// Fetch service alerts
let alerts = try await manager.fetchServiceAlerts(from: .sncfTER)
```

### Create a Custom DataSource

```swift
import LocomoSwiftGTFS

let mySource = DataSource(
    identifier: "flixbus-de",
    displayName: "FlixBus Germany",
    staticFeedURL: URL(string: "https://example.com/gtfs.zip"),
    staticRefreshInterval: 86_400,    // 24 hours
    realtimeFeeds: [
        .tripUpdates: URL(string: "https://example.com/trip-updates.pb")!,
        .serviceAlerts: URL(string: "https://example.com/alerts.pb")!,
    ],
    realtimeCacheTTL: 60              // 60 seconds
)

let feed = try await Feed(from: mySource)
let updates = try await manager.fetchTripUpdates(from: mySource)
```

### API Key Authentication

Some providers (like Swiss SBB) require an API key. LocomoSwift supports two authentication methods:

```swift
// Option 1: Use a preset and inject your API key
let mySBB = DataSource.sbb.withAuthentication(
    .queryParam(name: "api_key", value: "YOUR_KEY")
)
let updates = try await manager.fetchTripUpdates(from: mySBB)

// Option 2: Create a fully custom source with header auth
let custom = DataSource(
    identifier: "my-provider",
    displayName: "My Provider",
    authentication: .header(name: "Authorization", value: "Bearer YOUR_TOKEN"),
    staticFeedURL: URL(string: "https://api.example.com/gtfs.zip"),
    realtimeFeeds: [
        .tripUpdates: URL(string: "https://api.example.com/trip-updates.pb")!,
    ]
)
```

Authentication is applied automatically to all requests (static downloads and realtime fetches).

## Modules

| Module | Import | Description |
|--------|--------|-------------|
| **LocomoSwift** | `import LocomoSwift` | Umbrella — re-exports both modules below |
| **LocomoSwiftGTFS** | `import LocomoSwiftGTFS` | GTFS Static parsing: `Feed`, `DataSource`, `APIAuthentication`, models |
| **LocomoSwiftRT** | `import LocomoSwiftRT` | GTFS Realtime: `RealtimeManager`, mappers, models |

## GTFS Data Support

| Component | File | Supported |
|-----------|------|:---------:|
| Agencies | `agency.txt` | ✅ |
| Stops | `stops.txt` | ✅ |
| Routes | `routes.txt` | ✅ |
| Trips | `trips.txt` | ✅ |
| Stop Times | `stop_times.txt` | ✅ |
| Calendar Dates | `calendar_dates.txt` | ✅ |
| Calendar | `calendar.txt` | ❌ |
| Fare Attributes | `fare_attributes.txt` | ❌ |
| Fare Rules | `fare_rules.txt` | ❌ |
| Shapes | `shapes.txt` | ✅ |
| Frequencies | `frequencies.txt` | ❌ |
| Transfers | `transfers.txt` | ❌ |
| Feed Info | `feed_info.txt` | ❌ |

## GTFS Realtime Support

| Feed Type | Supported |
|-----------|:---------:|
| Trip Updates | ✅ |
| Vehicle Positions | ✅ |
| Service Alerts | ✅ |

## DataSource Presets

| Preset | Identifier | Static | Realtime | Auth Required | Static Refresh | RT Cache TTL |
|--------|-----------|:------:|:--------:|:-------------:|:--------------:|:------------:|
| `.sncfTER` | `sncf-ter` | ✅ | Trip Updates, Alerts | ❌ | 24h | 120s |
| `.sncfTGV` | `sncf-tgv` | ✅ | Trip Updates, Alerts | ❌ | 24h | 120s |
| `.sncfIntercites` | `sncf-intercites` | ✅ | Trip Updates, Alerts | ❌ | 24h | 120s |
| `.breizhgoTER` | `breizhgo-ter` | ✅ | Trip Updates, Alerts | ❌ | 24h | 120s |
| `.tamMontpellier` | `tam-montpellier` | ✅ | All three | ❌ | 7 days | 60s |
| `.sbb` | `sbb` | ✅ | Trip Updates, Alerts | ✅ API key | ~6 months | 30s |

> **Note:** The SBB preset ships without an API key. Register at [opentransportdata.swiss](https://opentransportdata.swiss) to obtain one, then use `.sbb.withAuthentication(...)`.

## Documentation

LocomoSwift ships with a full **DocC** catalogue for both modules:

- [`LocomoSwiftGTFS`](Sources/LocomoSwiftGTFS/LocomoSwiftGTFS.docc) — Getting Started, DataSource configuration, working with Shapes
- [`LocomoSwiftRT`](Sources/LocomoSwiftRT/LocomoSwiftRT.docc) — Fetching realtime data

The doc is hosted on [Swift Package Index](https://swiftpackageindex.com/RailMapiOS/LocomoSwift/documentation) and rebuilt automatically on every release.

To preview locally, open the package in Xcode and choose **Product > Build Documentation** (⌃⇧⌘D).

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Adding a new DataSource preset

To add a preset for a new transit provider, add a `static let` to the `DataSource` extension in `DataSource.swift`:

```swift
extension DataSource {
    public static let myProvider = DataSource(
        identifier: "my-provider",
        displayName: "My Transit Provider",
        authentication: .queryParam(name: "key", value: "DEFAULT_OR_EMPTY"),
        staticFeedURL: URL(string: "https://..."),
        realtimeFeeds: [
            .tripUpdates: URL(string: "https://...")!,
        ]
    )
}
```

## Acknowledgments

This project builds on the original [Transit](https://github.com/richwolf/transit) package by Rich Wolf. Many thanks for the foundational work on GTFS parsing in Swift.

## License

LocomoSwift is available under the MIT License. See the [LICENSE](LICENSE) file for more information.
