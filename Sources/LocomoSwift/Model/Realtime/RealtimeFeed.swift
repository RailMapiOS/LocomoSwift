//
//  RealtimeFeed.swift
//  LocomoSwift
//
//  Created by LocomoSwift on 2024.
//

import Foundation
import SwiftProtobuf

/// A parsed GTFS Realtime feed containing trip updates, vehicle positions, and alerts.
///
/// GTFS Realtime feeds are Protocol Buffer encoded binary data served over HTTP.
/// This struct parses the binary data and provides Swift-friendly access to the three
/// main entity types: trip updates, vehicle positions, and service alerts.
///
/// ### Example Usage
/// ```swift
/// // Load from a URL
/// let feed = try await RealtimeFeed(contentsOf: url)
/// print("Trip updates: \(feed.tripUpdates.count)")
/// print("Vehicles: \(feed.vehiclePositions.count)")
/// print("Alerts: \(feed.alerts.count)")
///
/// // Load from raw data
/// let feed = try RealtimeFeed(data: protobufData)
/// ```
public struct RealtimeFeed: Sendable {
    /// Metadata about the feed.
    public let header: Header
    /// Realtime trip updates (delays, cancellations, changed routes).
    public let tripUpdates: [RTTripUpdate]
    /// Realtime vehicle positions.
    public let vehiclePositions: [RTVehiclePosition]
    /// Service alerts (disruptions, incidents).
    public let alerts: [RTAlert]

    /// Metadata about a GTFS Realtime feed.
    public struct Header: Sendable {
        /// Version of the GTFS Realtime specification (e.g., "2.0").
        public let gtfsRealtimeVersion: String
        /// Whether this feed is a full dataset or a differential update.
        public let incrementality: Incrementality
        /// Moment when the feed content was created.
        public let timestamp: Date?
        /// The feed_version string from the corresponding GTFS feed_info.
        public let feedVersion: String?
    }

    /// Whether the feed is a full dataset or a differential update.
    public enum Incrementality: Int, Sendable {
        case fullDataset = 0
        case differential = 1
    }

    /// Initializes a `RealtimeFeed` by fetching and parsing GTFS Realtime data from a URL.
    ///
    /// - Parameter url: The URL of the GTFS Realtime feed (Protocol Buffer binary format).
    /// - Throws: `LSError.realtimeFetchFailed` if the HTTP request fails,
    ///           `LSError.invalidProtobuf` if the data cannot be parsed.
    public init(contentsOf url: URL) async throws {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw LSError.realtimeFetchFailed
        }

        try self.init(data: data)
    }

    /// Initializes a `RealtimeFeed` by parsing raw GTFS Realtime Protocol Buffer data.
    ///
    /// - Parameter data: The raw Protocol Buffer binary data.
    /// - Throws: `LSError.invalidProtobuf` if the data cannot be parsed.
    public init(data: Data) throws {
        let feedMessage: TransitRealtime_FeedMessage
        do {
            feedMessage = try TransitRealtime_FeedMessage(serializedBytes: data)
        } catch {
            throw LSError.invalidProtobuf
        }

        self.header = Header(from: feedMessage.header)

        var tripUpdates: [RTTripUpdate] = []
        var vehiclePositions: [RTVehiclePosition] = []
        var alerts: [RTAlert] = []

        for entity in feedMessage.entity {
            if entity.hasTripUpdate {
                tripUpdates.append(RTTripUpdate(from: entity.tripUpdate))
            }
            if entity.hasVehicle {
                vehiclePositions.append(RTVehiclePosition(from: entity.vehicle))
            }
            if entity.hasAlert {
                alerts.append(RTAlert(from: entity.alert))
            }
        }

        self.tripUpdates = tripUpdates
        self.vehiclePositions = vehiclePositions
        self.alerts = alerts
    }
}

// MARK: - Internal Protobuf Conversion

extension RealtimeFeed.Header {
    init(from proto: TransitRealtime_FeedHeader) {
        self.gtfsRealtimeVersion = proto.gtfsRealtimeVersion
        self.incrementality = RealtimeFeed.Incrementality(rawValue: proto.incrementality.rawValue) ?? .fullDataset
        self.timestamp = proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : nil
        self.feedVersion = proto.hasFeedVersion ? proto.feedVersion : nil
    }
}
