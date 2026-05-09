//
//  ServiceAlertMapper.swift
//  LocomoSwift
//

import Foundation
import SwiftProtobuf

enum ServiceAlertMapper {

    static func mapServiceAlerts(from feedMessage: TransitRealtime_FeedMessage) -> [RealtimeServiceAlert] {
        feedMessage.entity.compactMap { entity in
            guard entity.hasAlert, !entity.isDeleted else { return nil }
            return mapServiceAlert(entity.alert, alertID: entity.id)
        }
    }

    static func mapServiceAlert(_ alert: TransitRealtime_Alert, alertID: String) -> RealtimeServiceAlert {
        RealtimeServiceAlert(
            alertID: alertID,
            cause: alert.hasCause ? AlertCause(rawValue: Int(alert.cause.rawValue)) : nil,
            effect: alert.hasEffect ? AlertEffect(rawValue: Int(alert.effect.rawValue)) : nil,
            severityLevel: alert.hasSeverityLevel
                ? AlertSeverityLevel(rawValue: Int(alert.severityLevel.rawValue))
                : nil,
            url: alert.hasURL ? TranslatedStringMapper.map(alert.url) : nil,
            headerText: alert.hasHeaderText ? TranslatedStringMapper.map(alert.headerText) : nil,
            descriptionText: alert.hasDescriptionText ? TranslatedStringMapper.map(alert.descriptionText) : nil,
            ttsHeaderText: alert.hasTtsHeaderText ? TranslatedStringMapper.map(alert.ttsHeaderText) : nil,
            ttsDescriptionText: alert.hasTtsDescriptionText ? TranslatedStringMapper.map(alert.ttsDescriptionText) : nil,
            causeDetail: alert.hasCauseDetail ? TranslatedStringMapper.map(alert.causeDetail) : nil,
            effectDetail: alert.hasEffectDetail ? TranslatedStringMapper.map(alert.effectDetail) : nil,
            image: alert.hasImage ? TranslatedStringMapper.mapImage(alert.image) : nil,
            imageAlternativeText: alert.hasImageAlternativeText ? TranslatedStringMapper.map(alert.imageAlternativeText) : nil,
            activePeriods: alert.activePeriod.map(TimeRangeMapper.map),
            informedEntities: alert.informedEntity.map(mapInformedEntity)
        )
    }

    private static func mapInformedEntity(_ proto: TransitRealtime_EntitySelector) -> AlertInformedEntity {
        AlertInformedEntity(
            agencyID: proto.hasAgencyID ? proto.agencyID : nil,
            routeID: proto.hasRouteID ? proto.routeID : nil,
            routeType: proto.hasRouteType ? proto.routeType : nil,
            trip: proto.hasTrip ? TripDescriptorMapper.map(proto.trip) : nil,
            stopID: proto.hasStopID ? proto.stopID : nil,
            directionID: proto.hasDirectionID ? proto.directionID : nil
        )
    }
}
