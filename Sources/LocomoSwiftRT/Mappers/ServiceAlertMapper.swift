//
//  ServiceAlertMapper.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//


import Foundation
import SwiftProtobuf

public struct ServiceAlertMapper {
    
    static func mapServiceAlerts(from feedMessage: TransitRealtime_FeedMessage) -> [RealtimeServiceAlert] {
        return feedMessage.entity.compactMap { entity in
            guard entity.hasAlert else { return nil }
            return mapServiceAlert(entity.alert, alertID: entity.id)
        }
    }
    
    private static func mapServiceAlert(_ alert: TransitRealtime_Alert, alertID: String) -> RealtimeServiceAlert {
        let cause = alert.hasCause ? AlertCause(rawValue: Int(alert.cause.rawValue)) : nil
        let effect = alert.hasEffect ? AlertEffect(rawValue: Int(alert.effect.rawValue)) : nil
        
        let url = alert.hasURL ? URL(string: extractTranslatedString(alert.url)) : nil
        let headerText = alert.hasHeaderText ? extractTranslatedString(alert.headerText) : nil
        let descriptionText = alert.hasDescriptionText ? extractTranslatedString(alert.descriptionText) : nil
        
        let activePeriods = alert.activePeriod.map { mapActivePeriod($0) }
        let informedEntities = alert.informedEntity.map { mapInformedEntity($0) }
        
        return RealtimeServiceAlert(
            alertID: alertID,
            cause: cause,
            effect: effect,
            url: url,
            headerText: headerText,
            descriptionText: descriptionText,
            activePeriods: activePeriods,
            informedEntities: informedEntities
        )
    }
    
    private static func mapActivePeriod(_ period: TransitRealtime_TimeRange) -> AlertActivePeriod {
        let start = period.hasStart ? Date(timeIntervalSince1970: TimeInterval(period.start)) : nil
        let end = period.hasEnd ? Date(timeIntervalSince1970: TimeInterval(period.end)) : nil
        
        return AlertActivePeriod(start: start, end: end)
    }
    
    private static func mapInformedEntity(_ entity: TransitRealtime_EntitySelector) -> AlertInformedEntity {
        return AlertInformedEntity(
            agencyID: entity.hasAgencyID ? entity.agencyID : nil,
            routeID: entity.hasRouteID ? entity.routeID : nil,
            routeType: entity.hasRouteType ? entity.routeType : nil,
            tripID: entity.hasTrip ? entity.trip.tripID : nil,
            stopID: entity.hasStopID ? entity.stopID : nil,
            directionID: entity.hasDirectionID ? entity.directionID : nil
        )
    }
    
    private static func extractTranslatedString(_ translatedString: TransitRealtime_TranslatedString) -> String {
        // Take the first available translation
        // TODO: Improve to handle preferred languages
        return translatedString.translation.first?.text ?? ""
    }
}
