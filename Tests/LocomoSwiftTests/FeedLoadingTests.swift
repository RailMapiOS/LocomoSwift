//
//  FeedLoadingTests.swift
//  LocomoSwiftTests
//

import Foundation
import Testing
import LocomoSwift
import LocomoSwiftGTFS

@Suite("Feed Loading")
struct FeedLoadingTests {

    @Test("Loading the MiniGTFS folder fixture yields the expected counts across every collection")
    func loadsFromLocalFolder() async throws {
        let feed = try await Feed(contentsOfURL: Fixtures.miniGTFSFolderURL)

        #expect(feed.agencies?.count == 1)
        #expect(feed.routes?.routes.count == 1)
        #expect(feed.stops?.stops.count == 4)
        #expect(feed.trips?.trips.count == 2)
        #expect(feed.stopTimes?.stopTimes.count == 6)
        #expect(feed.calendarDates?.dates.count == 2)
    }

    @Test("Loading the MiniGTFS.zip via a file:// URL yields a feed equivalent to the folder version")
    func loadsFromLocalZip() async throws {
        let folder = try await Feed(contentsOfURL: Fixtures.miniGTFSFolderURL)
        let zipped = try await Feed(contentsOfURL: Fixtures.miniGTFSZipURL)

        #expect(folder.agencies?.count == zipped.agencies?.count)
        #expect(folder.stops?.stops.count == zipped.stops?.stops.count)
        #expect(folder.trips?.trips.count == zipped.trips?.trips.count)
        #expect(folder.stopTimes?.stopTimes.count == zipped.stopTimes?.stopTimes.count)

        let folderStopIDs = (folder.stops?.stops.map(\.stopID) ?? []).sorted()
        let zippedStopIDs = (zipped.stops?.stops.map(\.stopID) ?? []).sorted()
        #expect(folderStopIDs == zippedStopIDs)

        let folderTripIDs = (folder.trips?.trips.map(\.tripID) ?? []).sorted()
        let zippedTripIDs = (zipped.trips?.trips.map(\.tripID) ?? []).sorted()
        #expect(folderTripIDs == zippedTripIDs)
    }

    @Test("Loading a folder missing agency.txt fails with a thrown error")
    func missingAgencyThrows() async throws {
        let dir = try Fixtures.makeTempCopyOfMiniGTFS()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.removeItem(at: dir.appendingPathComponent("agency.txt"))

        await #expect(throws: (any Error).self) {
            _ = try await Feed(contentsOfURL: dir)
        }
    }

    @Test("Stop time arrival and departure are decoded into Date values in the agency timezone")
    func stopTimesDecodeIntoDates() async throws {
        let feed = try await Feed(contentsOfURL: Fixtures.miniGTFSFolderURL)
        let stopTimes = try #require(feed.stopTimes)
        #expect(stopTimes.stopTimes.allSatisfy { $0.arrival != nil })
        #expect(stopTimes.stopTimes.allSatisfy { $0.departure != nil })
        let first = try #require(stopTimes.stopTimes.first { $0.tripID == "T1" && $0.stopID == "S1" })
        #expect(first.timeZone.identifier == "Europe/Paris")
    }
}
