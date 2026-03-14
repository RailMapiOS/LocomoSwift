//
//  RealtimeAlert.swift
//  LocomoSwift
//
//  Created by LocomoSwift on 2024.
//

import Foundation

/// An alert, indicating some sort of incident in the public transit network.
public struct RTAlert: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// Time ranges when the alert is active.
    public let activePeriods: [RTTimeRange]
    /// Entities whose users should be notified of this alert.
    public let informedEntities: [RTEntitySelector]
    /// Cause of this alert.
    public let cause: Cause
    /// Effect of this alert on the affected entity.
    public let effect: Effect
    /// URL providing additional information about the alert.
    public let url: RTTranslatedString?
    /// Header text for the alert (short plain-text summary).
    public let headerText: RTTranslatedString?
    /// Full description for the alert.
    public let descriptionText: RTTranslatedString?
    /// Text for text-to-speech header.
    public let ttsHeaderText: RTTranslatedString?
    /// Text for text-to-speech description.
    public let ttsDescriptionText: RTTranslatedString?
    /// Severity of this alert.
    public let severityLevel: SeverityLevel

    public init(id: UUID = UUID(), activePeriods: [RTTimeRange] = [],
                informedEntities: [RTEntitySelector] = [],
                cause: Cause = .unknownCause, effect: Effect = .unknownEffect,
                url: RTTranslatedString? = nil, headerText: RTTranslatedString? = nil,
                descriptionText: RTTranslatedString? = nil,
                ttsHeaderText: RTTranslatedString? = nil, ttsDescriptionText: RTTranslatedString? = nil,
                severityLevel: SeverityLevel = .unknownSeverity) {
        self.id = id
        self.activePeriods = activePeriods
        self.informedEntities = informedEntities
        self.cause = cause
        self.effect = effect
        self.url = url
        self.headerText = headerText
        self.descriptionText = descriptionText
        self.ttsHeaderText = ttsHeaderText
        self.ttsDescriptionText = ttsDescriptionText
        self.severityLevel = severityLevel
    }

    // MARK: - Cause

    public enum Cause: Int, Sendable {
        case unknownCause = 1
        case otherCause = 2
        case technicalProblem = 3
        case strike = 4
        case demonstration = 5
        case accident = 6
        case holiday = 7
        case weather = 8
        case maintenance = 9
        case construction = 10
        case policeActivity = 11
        case medicalEmergency = 12
    }

    // MARK: - Effect

    public enum Effect: Int, Sendable {
        case noService = 1
        case reducedService = 2
        case significantDelays = 3
        case detour = 4
        case additionalService = 5
        case modifiedService = 6
        case otherEffect = 7
        case unknownEffect = 8
        case stopMoved = 9
        case noEffect = 10
        case accessibilityIssue = 11
    }

    // MARK: - SeverityLevel

    public enum SeverityLevel: Int, Sendable {
        case unknownSeverity = 1
        case info = 2
        case warning = 3
        case severe = 4
    }
}

// MARK: - Internal Protobuf Conversion

extension RTAlert {
    init(from proto: TransitRealtime_Alert) {
        self.id = UUID()
        self.activePeriods = proto.activePeriod.map { RTTimeRange(from: $0) }
        self.informedEntities = proto.informedEntity.map { RTEntitySelector(from: $0) }
        self.cause = Cause(rawValue: proto.cause.rawValue) ?? .unknownCause
        self.effect = Effect(rawValue: proto.effect.rawValue) ?? .unknownEffect
        self.url = proto.hasURL ? RTTranslatedString(from: proto.url) : nil
        self.headerText = proto.hasHeaderText ? RTTranslatedString(from: proto.headerText) : nil
        self.descriptionText = proto.hasDescriptionText ? RTTranslatedString(from: proto.descriptionText) : nil
        self.ttsHeaderText = proto.hasTtsHeaderText ? RTTranslatedString(from: proto.ttsHeaderText) : nil
        self.ttsDescriptionText = proto.hasTtsDescriptionText ? RTTranslatedString(from: proto.ttsDescriptionText) : nil
        self.severityLevel = SeverityLevel(rawValue: proto.severityLevel.rawValue) ?? .unknownSeverity
    }
}
