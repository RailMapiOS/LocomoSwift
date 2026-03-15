//
//  TripRealtimeStatus.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//


import Foundation
import LocomoSwiftGTFS

extension StopTime {

    /// Realtime arrival delay in seconds.
    public var realtimeArrivalDelay: Int32? {
        // TODO: Implement delay storage
        return nil
    }

    /// Realtime departure delay in seconds.
    public var realtimeDepartureDelay: Int32? {
        // TODO: Implement delay storage
        return nil
    }

    /// Predicted arrival time (static + delay).
    public var predictedArrival: Date? {
        guard let arrival = arrival else { return nil }

        if let delay = realtimeArrivalDelay {
            return arrival.addingTimeInterval(TimeInterval(delay))
        }

        return arrival
    }

    /// Predicted departure time (static + delay).
    public var predictedDeparture: Date? {
        guard let departure = departure else { return nil }

        if let delay = realtimeDepartureDelay {
            return departure.addingTimeInterval(TimeInterval(delay))
        }

        return departure
    }
}
