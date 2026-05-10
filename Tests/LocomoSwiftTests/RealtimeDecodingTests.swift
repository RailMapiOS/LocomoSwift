//
//  RealtimeDecodingTests.swift
//  LocomoSwiftTests
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
import LocomoSwift
import LocomoSwiftGTFS
@testable import LocomoSwiftRT

@Suite("Realtime Decoding", .serialized)
struct RealtimeDecodingTests {

    /// Build a deterministic FeedMessage with one TripUpdate, one VehiclePosition, and one Alert.
    private static func makeFeedMessage() -> TransitRealtime_FeedMessage {
        var feed = TransitRealtime_FeedMessage()
        feed.header.gtfsRealtimeVersion = "2.0"
        feed.header.timestamp = 1_700_000_000

        // 1) TripUpdate entity
        var tripDescriptor = TransitRealtime_TripDescriptor()
        tripDescriptor.tripID = "T1"
        tripDescriptor.routeID = "R1"

        var stopTimeUpdate = TransitRealtime_TripUpdate.StopTimeUpdate()
        stopTimeUpdate.stopID = "S2"
        stopTimeUpdate.stopSequence = 2
        var arrival = TransitRealtime_TripUpdate.StopTimeEvent()
        arrival.delay = 60
        arrival.time = 1_700_000_120
        stopTimeUpdate.arrival = arrival
        var departure = TransitRealtime_TripUpdate.StopTimeEvent()
        departure.delay = 90
        departure.time = 1_700_000_180
        stopTimeUpdate.departure = departure

        var tripUpdate = TransitRealtime_TripUpdate()
        tripUpdate.trip = tripDescriptor
        tripUpdate.stopTimeUpdate = [stopTimeUpdate]
        tripUpdate.timestamp = 1_700_000_000
        tripUpdate.delay = 60

        var entity1 = TransitRealtime_FeedEntity()
        entity1.id = "trip-T1"
        entity1.tripUpdate = tripUpdate

        // 2) VehiclePosition entity
        var vehicleDescriptor = TransitRealtime_VehicleDescriptor()
        vehicleDescriptor.id = "V42"

        var position = TransitRealtime_Position()
        position.latitude = 48.8584
        position.longitude = 2.2945
        position.bearing = 90
        position.speed = 25.5

        var vehiclePosition = TransitRealtime_VehiclePosition()
        vehiclePosition.trip = tripDescriptor
        vehiclePosition.vehicle = vehicleDescriptor
        vehiclePosition.position = position
        vehiclePosition.timestamp = 1_700_000_010

        var entity2 = TransitRealtime_FeedEntity()
        entity2.id = "vehicle-V42"
        entity2.vehicle = vehiclePosition

        feed.entity = [entity1, entity2]
        return feed
    }

    @Test("Mapping a FeedMessage TripUpdate yields a RealtimeTripUpdate with delays and stop time updates preserved")
    func mapsTripUpdates() throws {
        let feed = Self.makeFeedMessage()
        let updates = TripUpdateMapper.mapTripUpdates(from: feed)

        #expect(updates.count == 1)
        let u = try #require(updates.first)
        #expect(u.tripID == "T1")
        #expect(u.routeID == "R1")
        #expect(u.delay == 60)
        #expect(u.stopTimeUpdates.count == 1)
        let stu = try #require(u.stopTimeUpdates.first)
        #expect(stu.stopID == "S2")
        #expect(stu.stopSequence == 2)
        #expect(stu.arrivalDelay == 60)
        #expect(stu.departureDelay == 90)
    }

    @Test("Mapping a FeedMessage VehiclePosition yields a RealtimeVehiclePosition with lat/lon/bearing preserved")
    func mapsVehiclePositions() throws {
        let feed = Self.makeFeedMessage()
        let positions = VehiclePositionMapper.mapVehiclePositions(from: feed)

        #expect(positions.count == 1)
        let p = try #require(positions.first)
        #expect(p.vehicleID == "V42")
        #expect(p.tripID == "T1")
        // Position lat/lon are encoded as Float in protobuf; compare with tolerance.
        let lat = try #require(p.latitude)
        let lon = try #require(p.longitude)
        #expect(abs(lat - 48.8584) < 0.0001)
        #expect(abs(lon - 2.2945) < 0.0001)
        #expect(p.bearing == 90)
        #expect(p.speed == 25.5)
    }

    @Test("A FeedMessage round-trips through serialization and back without loss of trip ID or stop counts")
    func roundTripSerialization() throws {
        let original = Self.makeFeedMessage()
        let bytes = try original.serializedBytes() as Data
        let decoded = try TransitRealtime_FeedMessage(serializedBytes: bytes)

        #expect(decoded.entity.count == 2)
        let updates = TripUpdateMapper.mapTripUpdates(from: decoded)
        #expect(updates.first?.tripID == "T1")
        #expect(updates.first?.stopTimeUpdates.first?.stopID == "S2")
    }

    @Test("Decoding malformed bytes throws an error")
    func malformedBytesThrow() throws {
        let bogus = Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        #expect(throws: (any Error).self) {
            _ = try TransitRealtime_FeedMessage(serializedBytes: bogus)
        }
    }

    @Test("RealtimeManager.fetchTripUpdates parses bytes returned by an injected URLSession and applies authentication")
    func realtimeManagerFetchesTripUpdatesViaMockURLSession() async throws {
        let bytes = try Self.makeFeedMessage().serializedBytes() as Data
        let session = MockURLProtocol.makeSession()

        let expectedKey = "MY-API-KEY"
        MockURLProtocol.handler = { request in
            // Authentication via query parameter must reach the request URL.
            let comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let key = comps?.queryItems?.first { $0.name == "api_key" }?.value
            #expect(key == expectedKey)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, bytes)
        }
        defer { MockURLProtocol.reset() }

        let manager = RealtimeManager(urlSession: session)
        let source = DataSource(
            identifier: "mock",
            displayName: "Mock",
            authentication: .queryParam(name: "api_key", value: expectedKey),
            realtimeFeeds: [.tripUpdates: URL(string: "https://example.com/rt")!]
        )

        let updates = try await manager.fetchTripUpdates(from: source)
        #expect(updates.count == 1)
        #expect(updates.first?.tripID == "T1")
    }

    @Test("RealtimeManager throws RealtimeError.networkError when the upstream returns a non-200 response")
    func realtimeManagerThrowsOnNon200() async throws {
        let session = MockURLProtocol.makeSession()
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        defer { MockURLProtocol.reset() }

        let manager = RealtimeManager(urlSession: session)
        let source = DataSource(
            identifier: "mock",
            displayName: "Mock",
            realtimeFeeds: [.tripUpdates: URL(string: "https://example.com/rt")!]
        )

        await #expect(throws: RealtimeError.self) {
            _ = try await manager.fetchTripUpdates(from: source)
        }
    }
}
