//
//  TimeRangeMapper.swift
//  LocomoSwift
//

import Foundation

enum TimeRangeMapper {

    static func map(_ proto: TransitRealtime_TimeRange) -> AlertActivePeriod {
        AlertActivePeriod(
            start: proto.hasStart ? Date(timeIntervalSince1970: TimeInterval(proto.start)) : nil,
            end: proto.hasEnd ? Date(timeIntervalSince1970: TimeInterval(proto.end)) : nil
        )
    }
}
