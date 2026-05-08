//
//  CSVParsingTests.swift
//  LocomoSwiftTests
//

import Foundation
import Testing
import LocomoSwift
import LocomoSwiftGTFS

@Suite("CSV Parsing")
struct CSVParsingTests {

    @Test("Decoding stops.txt yields the expected stops with correct geographic fields")
    func decodesStops() throws {
        let stops = try Stops(from: try Fixtures.miniGTFSContent("stops.txt"))

        #expect(stops.stops.count == 4)
        let alpha = try #require(stops.stops.first { $0.stopID == "S1" })
        #expect(alpha.name == "Alpha")
        #expect(alpha.latitude == 48.8584)
        #expect(alpha.longitude == 2.2945)

        let ids = stops.stops.map(\.stopID).sorted()
        #expect(ids == ["S1", "S2", "S3", "S4"])
    }

    @Test("Decoding routes.txt yields the expected route ID and rail RouteType")
    func decodesRoutes() throws {
        let routes = try Routes(from: try Fixtures.miniGTFSContent("routes.txt"))

        #expect(routes.routes.count == 1)
        let r = try #require(routes.routes.first)
        #expect(r.routeID == "R1")
        #expect(r.shortName == "1")
        #expect(r.name == "North Express")
        #expect(r.type == .rail)
        #expect(r.color != nil)
    }

    @Test("Decoding agency.txt yields the agency timezone and locale")
    func decodesAgency() throws {
        let agencies = try Agencies(from: try Fixtures.miniGTFSContent("agency.txt"))

        #expect(agencies.count == 1)
        let a = try #require(agencies.first)
        #expect(a.name == "Mini Rail")
        #expect(a.timeZone.identifier == "Europe/Paris")
        #expect(a.locale?.identifier == "fr")
        #expect(agencies.isValid)
    }

    @Test("A header row with fewer columns than the data row throws LSError.headerRecordMismatch")
    func malformedRecordThrows() throws {
        let csv = "stop_id,stop_name,stop_lat\nS1,Alpha,48.0,2.3\n"
        #expect(throws: LSError.self) {
            _ = try Stops(from: csv)
        }
    }

    @Test("A header-only file (no data rows) returns an empty collection without throwing")
    func emptyDataReturnsEmpty() throws {
        let csv = "stop_id,stop_name,stop_lat,stop_lon\n"
        let stops = try Stops(from: csv)
        #expect(stops.stops.isEmpty)
    }

    @Test("Optional columns absent from the header are nil on decoded records")
    func optionalColumnsNilWhenAbsent() throws {
        let csv = "stop_id,stop_name\nS1,Alpha\nS2,Bravo\n"
        let stops = try Stops(from: csv)

        #expect(stops.stops.count == 2)
        let alpha = try #require(stops.stops.first { $0.stopID == "S1" })
        #expect(alpha.code == nil)
        #expect(alpha.latitude == nil)
        #expect(alpha.longitude == nil)
        #expect(alpha.url == nil)
    }

    @Test("RouteType.routeTypeFrom decodes valid GTFS route_type values",
          arguments: [("0", UInt(0)),
                      ("1", UInt(1)),
                      ("2", UInt(2)),
                      ("3", UInt(3)),
                      ("4", UInt(4))])
    func routeTypeFromString(raw: String, expectedRaw: UInt) {
        let expected = RouteType(rawValue: expectedRaw)
        #expect(Route.routeTypeFrom(string: raw) == expected)
    }

    @Test("StopLocationType.from decodes valid GTFS location_type values",
          arguments: [("0", UInt(0)),
                      ("1", UInt(1)),
                      ("2", UInt(2))])
    func stopLocationTypeFromString(raw: String, expectedRaw: UInt) {
        let expected = StopLocationType(rawValue: expectedRaw)
        #expect(Stop.stopLocationTypeFrom(string: raw) == expected)
    }
}
