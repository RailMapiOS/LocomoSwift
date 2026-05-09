//
//  ProtobufFeedMessageDecoder.swift
//  LocomoSwift
//
//  Default GTFS-RT decoder built on top of SwiftProtobuf and the per-type
//  mappers shipped with LocomoSwiftRT.
//

import Foundation
import LocomoSwiftGTFS
import SwiftProtobuf

public struct ProtobufFeedMessageDecoder: FeedMessageDecoding {

    public init() {}

    public func decode(_ data: Data) throws -> RealtimeFeed {
        let proto: TransitRealtime_FeedMessage
        do {
            proto = try TransitRealtime_FeedMessage(serializedBytes: data)
        } catch {
            throw RealtimeError.parsingError
        }
        return FeedMessageMapper.map(proto)
    }
}
