# LocomoSwift

<img src="https://github.com/user-attachments/assets/4a4a8f7a-360f-4b5d-ac4b-c3e9c54cae7d" alt="LocomoSwift Logo" width="150" align="right">

LocomoSwift is a Swift package built for easy integration of SNCF's GTFS data, with added support for handling GTFS feeds from `.zip` URLs. This project builds on top of the original [Transit](https://github.com/) package, with enhancements tailored for loading and processing GTFS datasets from remote sources. Many thanks to the Transit team for their foundational work.

## Overview

The **General Transit Feed Specification (GTFS)** is a standardized format that allows public transport agencies to share their transit data with developers. GTFS consists of two main components:

- **GTFS Static**: Defines the fixed aspects of a transit system, such as routes, stops, and schedules.
- **GTFS Real-Time**: Deals with real-time data like vehicle locations and arrival time predictions (**Soon**).

LocomoSwift focuses on the **GTFS Static** format, with the added capability to fetch and parse GTFS datasets directly from `.zip` files hosted online, simplifying the integration of remote transit feeds.

## GTFS Data Support

The table below shows the various components of a GTFS feed and whether they are currently supported by LocomoSwift.

| GTFS Data Component       | Description                                    | Supported |
|---------------------------|------------------------------------------------|:---------:|
| `agency.txt`               | Information about the transit agencies         |    ✅    |
| `stops.txt`                | Details of transit stops and stations          |    ✅    |
| `routes.txt`               | Information about transit routes               |    ✅    |
| `trips.txt`                | Individual trips for each route                |    ✅    |
| `stop_times.txt`           | Times for each stop along a trip               |    ✅    |
| `calendar.txt`             | Service dates for the transit system           |    ❌    |
| `calendar_dates.txt`       | Exceptions for the regular service dates       |    ✅    |
| `fare_attributes.txt`      | Information about fare pricing                 |    ❌    |
| `fare_rules.txt`           | Rules for applying fare information            |    ❌    |
| `shapes.txt`               | Shapes for drawing routes on a map             |    ❌    |
| `frequencies.txt`          | Frequency-based trips rather than exact times  |    ❌    |
| `transfers.txt`            | Rules for passenger transfers between routes   |    ❌    |
| `feed_info.txt`            | Metadata about the GTFS feed                   |    ❌    |


## Installation

LocomoSwift is available via **Swift Package Manager (SPM)**. To add it to your Xcode project:

1. Open your project in Xcode.
2. Navigate to **File > Add Packages**.
3. In the search bar, enter:  
   `https://github.com/your-username/LocomoSwift.git`
4. Select the desired version or branch and click **Add Package** to include it in your project.

## Usage

LocomoSwift makes it easy to load GTFS data from a URL pointing to a `.zip` archive. Here’s an example of how to create a `Feed` instance from a remote `.zip` file and access key transit information such as agencies, routes, and stops:

```swift
// Load a GTFS feed from a URL
let feedURL = URL(string: "https://example.com/gtfs.zip")!
let feed = Feed(contentsOfURL: feedURL)

// Access agency information
if let agencyName = feed.agency?.name {
	print(agencyName)
}

// List all routes from the feed
if let routes = feed.routes {
	for route in routes {
		print(route)
	}
}

// List all stops from the feed
if let stops = feed.stops {
	for stop in stops {
		print(stop)
	}
}
```

## Documentation
LocomoSwift utilizes Apple’s **DocC** for documentation. You can refer to the included documentation for detailed guidance on how to use the package, explore its features, and integrate it into your project.

