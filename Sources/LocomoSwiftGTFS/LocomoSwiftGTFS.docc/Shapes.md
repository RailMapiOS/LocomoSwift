# Working with Shapes

Render the physical path a vehicle takes along a route using GTFS shapes.

## Overview

The optional `shapes.txt` file in a GTFS feed describes the **geographic polyline** that vehicles follow when serving a trip — the curve you typically draw on a map between stops. Each shape is a sequence of latitude/longitude points indexed by an integer sequence number, and trips reference shapes by their identifier.

LocomoSwift exposes two types:

- ``ShapePoint`` — a single point: `shapeID`, `latitude`, `longitude`, `sequence`, optional `distanceTraveled`
- ``Shapes`` — the collection parsed from `shapes.txt`, with helpers to query by shape ID

> Note: `shapes.txt` is **optional** in the GTFS spec. Feeds without it still load; ``Feed/shapes`` is simply `nil`.

## Loading Shapes

Shapes are loaded automatically when present in a feed:

```swift
let feed = try await Feed(from: .sncfTER)

if let shapes = feed.shapes {
    print("Feed contains \(shapes.shapeIDs.count) shapes")
}
```

You can also load `shapes.txt` standalone — from a file, or directly from a CSV string:

```swift
// From a local file
let shapes = try Shapes(from: shapesFileURL)

// From in-memory CSV
let csv = """
shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence
S1,48.8584,2.2945,1
S1,48.8606,2.3376,2
S1,48.8738,2.2950,3
"""
let shapes = try Shapes(from: csv)
```

## Inspecting Shapes

Every unique shape identifier is exposed via ``Shapes/shapeIDs``:

```swift
for id in shapes.shapeIDs.sorted() {
    let points = shapes.pointsForShape(id)
    print("Shape \(id): \(points.count) points")
}
```

``Shapes/pointsForShape(_:)`` returns the points **sorted by `sequence`** — ready to be turned into a polyline without further work.

## Linking Trips to Shapes

A trip references its shape via ``Trip/shapeID``. Combine that with ``Shapes/pointsForShape(_:)`` to draw the path of a specific trip:

```swift
guard
    let trip = feed.trips?.trips.first(where: { $0.tripID == "T42" }),
    let shapeID = trip.shapeID,
    let shapes = feed.shapes
else { return }

let points = shapes.pointsForShape(shapeID)
```

## Drawing a Polyline (framework-agnostic)

The output of ``Shapes/pointsForShape(_:)`` is a plain `[ShapePoint]` — no UI framework involved. Convert it to whatever shape your rendering layer expects:

```swift
let coordinates: [(lat: Double, lon: Double)] = points.compactMap { point in
    guard let lat = point.latitude, let lon = point.longitude else { return nil }
    return (lat, lon)
}
```

This makes shapes usable from **any** environment — server-side Vapor (drawing GeoJSON), MapLibre, Mapbox iOS SDK, Leaflet via a JSON API, an Xcode preview, or simple distance computations:

```swift
// Total path length in degrees-of-arc (rough)
let total = zip(coordinates, coordinates.dropFirst()).reduce(0.0) { acc, pair in
    let (a, b) = pair
    let dlat = a.lat - b.lat
    let dlon = a.lon - b.lon
    return acc + (dlat * dlat + dlon * dlon).squareRoot()
}
```

## Example: MapKit (iOS / macOS)

On Apple platforms you can hand the same data to MapKit by converting each point to a `CLLocationCoordinate2D` and building an `MKPolyline`:

```swift
import MapKit

extension Shapes {
    /// Returns an `MKPolyline` for the given shape, suitable for `MKMapView.addOverlay(_:)`.
    func polyline(for shapeID: String) -> MKPolyline {
        let coordinates = pointsForShape(shapeID).compactMap { point -> CLLocationCoordinate2D? in
            guard let lat = point.latitude, let lon = point.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

// Usage
let polyline = feed.shapes?.polyline(for: "S1")
mapView.addOverlay(polyline!)
```

> Tip: this convenience extension lives in your app, not in LocomoSwiftGTFS — keeping the package free of MapKit so it remains usable on Linux and tvOS contexts where MapKit isn't available.

## Distance Traveled

GTFS optionally exposes how far along the shape each point sits, via the `shape_dist_traveled` column. LocomoSwift surfaces it as ``ShapePoint/distanceTraveled``:

```swift
for point in shapes.pointsForShape("S1") {
    if let distance = point.distanceTraveled {
        print("seq \(point.sequence): \(distance) units along shape")
    }
}
```

The unit is **producer-defined** — meters, kilometers, miles, feet… GTFS doesn't enforce one. Use it for relative ordering and progress computation, not for absolute distance unless you know what the producer chose.

## Topics

### Types

- ``Shapes``
- ``ShapePoint``
- ``ShapeField``
