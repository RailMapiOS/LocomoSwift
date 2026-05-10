//
//  DataSourceTests.swift
//  LocomoSwiftTests
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
import LocomoSwift
import LocomoSwiftGTFS

@Suite("DataSource")
struct DataSourceTests {

    @Test("A custom DataSource preserves its static feed URL and exposes the configured realtime feed types")
    func customDataSourceURLsArePreserved() throws {
        let staticURL = URL(string: "https://example.com/gtfs.zip")!
        let tuURL = URL(string: "https://example.com/rt/trip-updates.pb")!

        let source = DataSource(
            identifier: "custom",
            displayName: "Custom",
            staticFeedURL: staticURL,
            realtimeFeeds: [.tripUpdates: tuURL]
        )

        #expect(source.hasStaticFeed)
        #expect(source.availableRealtimeFeedTypes == [.tripUpdates])
        #expect(try source.url(for: .tripUpdates) == tuURL)
        #expect(try source.authenticatedStaticFeedURL() == staticURL)
    }

    @Test("APIAuthentication.queryParam appends the configured api_key to the URL")
    func queryParamAuthAppendsToURL() {
        let auth = APIAuthentication.queryParam(name: "api_key", value: "secret")
        let url = URL(string: "https://example.com/feed")!
        let authed = auth.authenticatedURL(url)

        let components = URLComponents(url: authed, resolvingAgainstBaseURL: false)
        let item = components?.queryItems?.first { $0.name == "api_key" }
        #expect(item?.value == "secret")
    }

    @Test("APIAuthentication.header sets the configured field on the request")
    func headerAuthSetsRequestHeader() {
        let auth = APIAuthentication.header(name: "Authorization", value: "Bearer abc")
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let authed = auth.authenticatedRequest(request)

        #expect(authed.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
    }

    @Test("DataSource.url(for:) throws RealtimeError.feedTypeNotAvailable for a feed type that wasn't configured")
    func urlForMissingFeedTypeThrows() {
        let source = DataSource(
            identifier: "x",
            displayName: "X",
            realtimeFeeds: [:]
        )
        #expect(throws: RealtimeError.self) {
            _ = try source.url(for: .vehiclePositions)
        }
    }

    @Test("DataSource.authenticatedStaticFeedURL throws when no static feed URL is configured")
    func staticFeedURLThrowsWhenAbsent() {
        let source = DataSource(identifier: "x", displayName: "X")
        #expect(throws: RealtimeError.self) {
            _ = try source.authenticatedStaticFeedURL()
        }
    }

    @Test("withAuthentication returns a copy that carries the new authentication while keeping URLs intact")
    func withAuthenticationReturnsCopyWithNewAuth() throws {
        let original = DataSource(
            identifier: "src",
            displayName: "S",
            staticFeedURL: URL(string: "https://example.com/gtfs.zip")!
        )
        let authed = original.withAuthentication(.queryParam(name: "key", value: "v"))

        let staticURL = try authed.authenticatedStaticFeedURL()
        let comps = URLComponents(url: staticURL, resolvingAgainstBaseURL: false)
        #expect(comps?.queryItems?.contains { $0.name == "key" && $0.value == "v" } == true)
        #expect(authed.identifier == original.identifier)
        #expect(authed.staticFeedURL == original.staticFeedURL)
    }

    @Test("The built-in SNCF TER preset advertises the expected identifier and realtime feed types")
    func sncfPresetIsConfigured() throws {
        let preset = DataSource.sncfTER
        #expect(preset.identifier == "sncf-ter")
        #expect(preset.hasStaticFeed)
        #expect(preset.availableRealtimeFeedTypes.contains(.tripUpdates))
        #expect(preset.availableRealtimeFeedTypes.contains(.serviceAlerts))
    }

    @Test("staticFeedNeedsRefresh respects the configured refresh interval")
    func staticFeedNeedsRefreshRespectsTTL() {
        let source = DataSource(
            identifier: "x",
            displayName: "X",
            staticFeedURL: URL(string: "https://example.com")!,
            staticRefreshInterval: 3600
        )
        #expect(source.staticFeedNeedsRefresh(since: Date(timeIntervalSinceNow: -7200)))
        #expect(!source.staticFeedNeedsRefresh(since: Date(timeIntervalSinceNow: -60)))
    }
}
