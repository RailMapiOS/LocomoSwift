# LocomoSwift

<img src="https://github.com/user-attachments/assets/4a4a8f7a-360f-4b5d-ac4b-c3e9c54cae7d" alt="LocomoSwift Logo" width="150" align="right">

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%20|%20macOS%2012%20|%20tvOS%2015%20|%20watchOS%208-blue)
![SPM](https://img.shields.io/badge/SPM-compatible-green)

A Swift package for parsing **GTFS Static** feeds and consuming **GTFS Realtime** data, with built-in presets for French transit networks and easy extensibility for any provider worldwide.

## Features

- **GTFS Static** — Parse ZIP or folder-based feeds: agencies, routes, stops, trips, stop times, calendar dates
- **GTFS Realtime** — Fetch trip updates, vehicle positions, and service alerts from protobuf feeds
- **DataSource presets** — Pre-configured sources for SNCF, TaM Montpellier, and more
- **Custom DataSources** — Inject your own endpoints for any transit provider
- **Actor-based concurrency** — Thread-safe realtime cache via Swift's `actor` model
- **Modular imports** — Import only what you need: static, realtime, or both

## Installation

Add LocomoSwift to your project via **Swift Package Manager**.

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/music-forest/LocomoSwift.git", from: "1.0.0")
]
```

Then add the desired product to your target:

```swift
// Everything (GTFS Static + Realtime)
.product(name: "LocomoSwift", package: "LocomoSwift")

// GTFS Static only
.product(name: "LocomoSwiftGTFS", package: "LocomoSwift")

// GTFS Realtime only
.product(name: "LocomoSwiftRT", package: "LocomoSwift")
```

## Quick Start

### Load a GTFS Static Feed

```swift
import LocomoSwiftGTFS

// From a preset DataSource
let feed = try await Feed(from: .sncf)

// From a custom URL
let url = URL(string: "https://example.com/gtfs.zip")!
let feed = try await Feed(contentsOfURL: url)

// Access transit data
feed.agencies?.forEach { print($0.name) }
feed.routes?.forEach { print($0.shortName) }
feed.stops?.forEach { print($0.name) }
```

### Fetch GTFS Realtime Data

```swift
import LocomoSwiftRT

let manager = RealtimeManager()

// Fetch trip updates
let updates = try await manager.fetchTripUpdates(from: .sncf)
for update in updates {
    print("\(update.tripID): delay \(update.stopTimeUpdates.first?.arrivalDelay ?? 0)s")
}

// Fetch service alerts
let alerts = try await manager.fetchServiceAlerts(from: .sncf)
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

## Modules

| Module | Import | Description |
|--------|--------|-------------|
| **LocomoSwift** | `import LocomoSwift` | Umbrella — re-exports both modules below |
| **LocomoSwiftGTFS** | `import LocomoSwiftGTFS` | GTFS Static parsing: `Feed`, `DataSource`, models |
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
| Shapes | `shapes.txt` | ❌ |
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

| Preset | Identifier | Static | Realtime | Static Refresh | RT Cache TTL |
|--------|-----------|:------:|:--------:|:--------------:|:------------:|
| `.sncf` | `sncf` | ✅ | Trip Updates, Alerts | 24h | 120s |
| `.tamMontpellier` | `tam-montpellier` | ✅ | Trip Updates, Positions, Alerts | 7 days | 60s |

## Documentation

LocomoSwift includes **DocC** documentation. Build it locally:

```bash
swift package generate-documentation
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

This project builds on the original [Transit](https://github.com/richwolf/transit) package by Rich Wolf. Many thanks for the foundational work on GTFS parsing in Swift.

## License

LocomoSwift is available under the MIT License. See the [LICENSE](LICENSE) file for more information.
