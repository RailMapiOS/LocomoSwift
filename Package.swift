// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocomoSwift",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        /// All-in-one: GTFS Static + Realtime
        .library(name: "LocomoSwift", targets: ["LocomoSwift"]),
        /// GTFS Static only (Feed, Agency, Route, Stop, Trip, StopTime, CalendarDate, DataSource)
        .library(name: "LocomoSwiftGTFS", targets: ["LocomoSwiftGTFS"]),
        /// GTFS Realtime only (RealtimeManager, protobuf, mappers)
        .library(name: "LocomoSwiftRT", targets: ["LocomoSwiftRT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMinor(from: "0.9.19")),
        .package(url: "https://github.com/apple/swift-protobuf.git", .upToNextMinor(from: "1.30.0"))
    ],
    targets: [
        // MARK: - GTFS Static
        .target(
            name: "LocomoSwiftGTFS",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ]
        ),

        // MARK: - GTFS Realtime
        .target(
            name: "LocomoSwiftRT",
            dependencies: [
                "LocomoSwiftGTFS",
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        ),

        // MARK: - Umbrella (re-exports GTFS + RT)
        .target(
            name: "LocomoSwift",
            dependencies: ["LocomoSwiftGTFS", "LocomoSwiftRT"]
        ),

        // MARK: - Tests
        .testTarget(
            name: "LocomoSwiftTests",
            dependencies: ["LocomoSwift"],
            resources: [
                .copy("Resources/export_gtfs_voyages.zip")
            ]
        ),
    ]
)
