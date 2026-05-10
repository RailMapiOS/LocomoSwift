# Getting Started with LocomoSwiftGTFS

Learn how to install LocomoSwift, load your first GTFS feed, and access transit data.

## Overview

LocomoSwiftGTFS makes it easy to parse GTFS Static feeds from ZIP archives hosted online or from local directories. This guide walks you through installation and basic usage.

## Add the Package

Add LocomoSwift to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/RailMapiOS/LocomoSwift.git", from: "1.3.0")
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
        let short = route.shortName ?? "?"
        let long = route.name ?? "Unnamed"
        print("Route \(short): \(long) (\(route.type))")
    }
}

// Stops
if let stops = feed.stops {
    print("Total stops: \(stops.stops.count)")
}

// Trips and stop times
if let trips = feed.trips {
    for trip in trips.trips.prefix(5) {
        print("Trip \(trip.tripID) — \(trip.headSign ?? "unknown")")
    }
}

// Shapes (optional in GTFS)
if let shapes = feed.shapes {
    for shapeID in shapes.shapeIDs {
        let points = shapes.pointsForShape(shapeID)
        print("Shape \(shapeID): \(points.count) points")
    }
}
```

## Parse In-Memory CSV

When you already have GTFS data in memory (custom transport, decompressed bundle, generated fixtures…) you can skip the filesystem entirely. Every collection accepts a CSV string directly:

```swift
let csv = """
stop_id,stop_name,stop_lat,stop_lon
S1,Alpha,48.8584,2.2945
S2,Bravo,48.8606,2.3376
"""

let stops = try Stops(from: csv)
```

The same pattern works for ``Agencies``, ``Routes``, ``Trips``, ``StopTimes`` (which also takes a `timeZone:`), ``CalendarDates``, and ``Shapes``.

## Keep Extracted Files

By default, temporary files are removed after parsing. To keep them (useful for debugging or caching):

```swift
let feed = try await Feed(contentsOfURL: url, keepFiles: true)
```

## Working with Route Colors

Routes carry their brand colors as ``LSColor`` — a portable RGBA value type that works on every platform LocomoSwift supports, including Linux.

```swift
if let color = route.color {
    print("RGBA: \(color.red), \(color.green), \(color.blue), \(color.alpha)")
}
```

On Apple platforms, a convenience getter bridges to `CGColor` for direct use with UIKit / AppKit / SwiftUI:

```swift
#if canImport(CoreGraphics)
let cg = route.color?.cgColor
#endif
```

## Use on Linux / Server-Side

Since version 1.3.0, LocomoSwiftGTFS compiles and runs on Linux, making it usable from a server-side Swift app — for example a Vapor backend that aggregates GTFS feeds and exposes them over a REST API:

```swift
import Vapor
import LocomoSwiftGTFS

func boot(_ app: Application) async throws {
    app.get("feeds", "sncf", "stops") { req async throws -> [StopDTO] in
        let feed = try await Feed(from: .sncfTER)
        return feed.stops?.stops.map(StopDTO.init) ?? []
    }
}
```

Tested on Linux x86_64 and ARM64 (Raspberry Pi 4/5, AWS Graviton) via the `swift:6.2-jammy` Docker image.

## Migrating from 1.2.x

Version 1.3.0 introduces a small breaking change to drop CoreGraphics from the package's surface:

| Before (1.2.x) | After (1.3.0) | Migration |
|---|---|---|
| `Route.color: CGColor?` | `Route.color: LSColor?` | Use `route.color?.cgColor` for the previous Apple-only `CGColor` |
| `Route.textColor: CGColor?` | `Route.textColor: LSColor?` | Same as above |
| `Stop.latitude: CLLocationDegrees?` | `Stop.latitude: Double?` | Transparent — `CLLocationDegrees` is a typealias for `Double` |
| `ShapePoint.latitude` / `.longitude` | Same | Same |

If your app only used `route.color` for SwiftUI / UIKit display, the migration is one line per call site:

```swift
// Before
imageView.tintColor = UIColor(cgColor: route.color!)

// After
imageView.tintColor = UIColor(cgColor: route.color!.cgColor)
```

## Next Steps

- Learn about configuring custom data sources in <doc:DataSourceConfiguration>
- Explore GTFS Realtime support with `LocomoSwiftRT`
