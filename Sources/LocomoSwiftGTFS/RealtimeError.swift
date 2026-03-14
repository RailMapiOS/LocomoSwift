//
//  RealtimeError.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation

/// Errors related to GTFS Realtime operations.
public enum RealtimeError: Error, LocalizedError {
    case networkError
    case invalidData
    case parsingError
    case feedTypeNotAvailable(RealtimeFeedType)
    case staticFeedNotConfigured(String)

    public var errorDescription: String? {
        switch self {
        case .networkError:
            "Network error while fetching realtime data"
        case .invalidData:
            "Invalid realtime data"
        case .parsingError:
            "Failed to parse realtime data"
        case .feedTypeNotAvailable(let type):
            "Realtime feed '\(type)' is not available for this source"
        case .staticFeedNotConfigured(let identifier):
            "DataSource '\(identifier)' has no staticFeedURL configured"
        }
    }
}
