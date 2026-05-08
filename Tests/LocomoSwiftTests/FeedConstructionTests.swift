//
//  FeedConstructionTests.swift
//  LocomoSwiftTests
//

import Foundation
import Testing
import LocomoSwift
import LocomoSwiftGTFS

@Suite("Feed Construction")
struct FeedConstructionTests {

    @Test("The all-fields Feed initializer assigns each provided collection and leaves others nil")
    func allFieldsInitAssigns() throws {
        let agencies = Agencies([
            Agency(agencyID: "A", name: "Acme", url: URL(string: "https://example.com")!)
        ])
        let stops = Stops([
            Stop(stopID: "S1", name: "Alpha"),
            Stop(stopID: "S2", name: "Bravo")
        ])

        let feed = try Feed(agencices: agencies, stops: stops)

        #expect(feed.agencies?.count == 1)
        #expect(feed.stops?.stops.count == 2)
        #expect(feed.routes == nil)
        #expect(feed.trips == nil)
        #expect(feed.stopTimes == nil)
        #expect(feed.calendarDates == nil)
    }

    @Test("Feed.agency convenience returns the first agency when present, nil when absent")
    func agencyConvenience() throws {
        let withAgency = try Feed(agencices: Agencies([Agency(name: "Acme")]))
        #expect(withAgency.agency?.name == "Acme")

        let empty = try Feed()
        #expect(empty.agency == nil)
    }

    @Test("A feed loaded from disk and reconstructed via the typed initializer preserves component counts")
    func diskLoadAndTypedInitAreEquivalent() async throws {
        let loaded = try await Feed(contentsOfURL: Fixtures.miniGTFSFolderURL)

        let rebuilt = try Feed(
            agencices: loaded.agencies,
            routes: loaded.routes,
            stops: loaded.stops,
            trips: loaded.trips,
            stopTimes: loaded.stopTimes,
            calendarDates: loaded.calendarDates
        )

        #expect(rebuilt.agencies?.count == loaded.agencies?.count)
        #expect(rebuilt.routes?.routes.count == loaded.routes?.routes.count)
        #expect(rebuilt.stops?.stops.count == loaded.stops?.stops.count)
        #expect(rebuilt.trips?.trips.count == loaded.trips?.trips.count)
        #expect(rebuilt.stopTimes?.stopTimes.count == loaded.stopTimes?.stopTimes.count)
        #expect(rebuilt.calendarDates?.dates.count == loaded.calendarDates?.dates.count)
    }
}
