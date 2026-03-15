# Getting Started with LocomoSwiftGTFS

Learn how to install LocomoSwift, load your first GTFS feed, and access transit data.

## Overview

LocomoSwiftGTFS makes it easy to parse GTFS Static feeds from ZIP archives hosted online or from local directories. This guide walks you through installation and basic usage.

## Add the Package

Add LocomoSwift to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/RailMapiOS/LocomoSwift.git", from: "1.0.0")
]
```

Then add the product to your target. You can choose between three options:

```swift
// GTFS Static only
.product(name: "LocomoSwiftGTFS", package: "LocomoSwift")

// GTFS Realtime only (includes LocomoSwiftGTFS)
.product(name: "LocomoSwiftRT", package: "LocomoSwift")

// Everything (Static + Realtime)
.product(name: "LocomoSwift", package: "LocomoSwift")
```

## Load a Feed from a Preset

The simplest way to get started is with a built-in ``DataSource`` preset:

```swift
import LocomoSwiftGTFS

let feed = try await Feed(from: .sncfTER)
```

This downloads the SNCF TER GTFS ZIP, extracts it to a temporary directory, parses all supported files, and cleans up automatically.

## Load a Feed from a URL

You can also load from any URL pointing to a GTFS ZIP archive:

```swift
let url = URL(string: "https://example.com/transit/gtfs.zip")!
let feed = try await Feed(contentsOfURL: url)
```

Or from a local directory containing extracted GTFS text files:

```swift
let directoryURL = URL(fileURLWithPath: "/path/to/gtfs-files/")
let feed = try await Feed(contentsOfURL: directoryURL)
```

## Access Transit Data

Once loaded, the ``Feed`` struct provides access to all parsed GTFS data:

```swift
// Agencies
if let agencies = feed.agencies {
    for agency in agencies {
        print("\(agency.name) — \(agency.url)")
    }
}

// Routes
if let routes = feed.routes {
    for route in routes {
        print("Route \(route.shortName): \(route.longName)")
    }
}

// Stops
if let stops = feed.stops {
    print("Total stops: \(stops.count)")
}

// Trips and stop times
if let trips = feed.trips {
    for trip in trips.prefix(5) {
        print("Trip \(trip.tripID) — \(trip.headSign ?? "unknown")")
    }
}
```

## Keep Extracted Files

By default, temporary files are removed after parsing. To keep them (useful for debugging or caching):

```swift
let feed = try await Feed(contentsOfURL: url, keepFiles: true)
```

## Next Steps

- Learn about configuring custom data sources in <doc:DataSourceConfiguration>
- Explore GTFS Realtime support with `LocomoSwiftRT`
