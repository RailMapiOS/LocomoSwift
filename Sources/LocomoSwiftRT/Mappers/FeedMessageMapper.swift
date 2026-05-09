//
//  FeedMessageMapper.swift
//  LocomoSwift
//
//  Top-level mapper that converts a `TransitRealtime_FeedMessage` into a
//  fully-typed ``RealtimeFeed``.
//

import Foundation
import SwiftProtobuf

enum FeedMessageMapper {

    static func map(_ proto: TransitRealtime_FeedMessage) -> RealtimeFeed {
        let header = mapHeader(proto.header)

        var tripUpdates: [RealtimeTripUpdate] = []
        var vehiclePositions: [RealtimeVehiclePosition] = []
        var serviceAlerts: [RealtimeServiceAlert] = []
        var shapes: [RealtimeShape] = []
        var deletedIDs: [String] = []

        for entity in proto.entity {
            if entity.isDeleted {
                deletedIDs.append(entity.id)
                continue
            }
            if entity.hasTripUpdate {
                tripUpdates.append(TripUpdateMapper.mapTripUpdate(entity.tripUpdate))
            }
            if entity.hasVehicle {
                vehiclePositions.append(VehiclePositionMapper.mapVehiclePosition(entity.vehicle))
            }
            if entity.hasAlert {
                serviceAlerts.append(ServiceAlertMapper.mapServiceAlert(entity.alert, alertID: entity.id))
            }
            if entity.hasShape {
                shapes.append(RealtimeShape(
                    id: entity.shape.shapeID,
                    encodedPolyline: entity.shape.encodedPolyline
                ))
            }
            // Note: entity.stop and entity.tripModifications are experimental
            // GTFS-RT v2.0 additions and are not yet mapped. They can be
            // accessed by consumers via a custom decoder if needed.
        }

        return RealtimeFeed(
            header: header,
            tripUpdates: tripUpdates,
            vehiclePositions: vehiclePositions,
            serviceAlerts: serviceAlerts,
            shapes: shapes,
            deletedEntityIDs: deletedIDs
        )
    }

    private static func mapHeader(_ proto: TransitRealtime_FeedHeader) -> RealtimeFeedHeader {
        RealtimeFeedHeader(
            gtfsRealtimeVersion: proto.hasGtfsRealtimeVersion ? proto.gtfsRealtimeVersion : "",
            incrementality: Incrementality(rawValue: Int(proto.incrementality.rawValue)) ?? .fullDataset,
            timestamp: proto.hasTimestamp ? Date(timeIntervalSince1970: TimeInterval(proto.timestamp)) : nil,
            feedVersion: proto.hasFeedVersion ? proto.feedVersion : nil
        )
    }
}
