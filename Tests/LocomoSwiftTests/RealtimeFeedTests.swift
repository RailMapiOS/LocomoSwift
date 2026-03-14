//
//  RealtimeFeedTests.swift
//  LocomoSwift
//
//  Tests for GTFS Realtime parsing.
//

import XCTest
@testable import LocomoSwift

final class RealtimeFeedTests: XCTestCase {

    // MARK: - Helper: Build a minimal protobuf feed

    /// Creates a valid GTFS-RT protobuf binary with a trip update entity.
    private func makeTripUpdateFeedData() throws -> Data {
        var header = TransitRealtime_FeedHeader()
        header.gtfsRealtimeVersion = "2.0"
        header.incrementality = .fullDataset
        header.timestamp = 1700000000

        var stopTimeEvent = TransitRealtime_TripUpdate.StopTimeEvent()
        stopTimeEvent.delay = 120
        stopTimeEvent.time = 1700000060

        var stopTimeUpdate = TransitRealtime_TripUpdate.StopTimeUpdate()
        stopTimeUpdate.stopSequence = 3
        stopTimeUpdate.stopID = "STOP_A"
        stopTimeUpdate.arrival = stopTimeEvent
        stopTimeUpdate.scheduleRelationship = .scheduled

        var tripDescriptor = TransitRealtime_TripDescriptor()
        tripDescriptor.tripID = "TRIP_1"
        tripDescriptor.routeID = "ROUTE_1"
        tripDescriptor.directionID = 0
        tripDescriptor.startDate = "20231114"

        var tripUpdate = TransitRealtime_TripUpdate()
        tripUpdate.trip = tripDescriptor
        tripUpdate.stopTimeUpdate = [stopTimeUpdate]
        tripUpdate.timestamp = 1700000000
        tripUpdate.delay = 120

        var entity = TransitRealtime_FeedEntity()
        entity.id = "entity_1"
        entity.tripUpdate = tripUpdate

        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header = header
        feedMessage.entity = [entity]

        return try feedMessage.serializedData()
    }

    /// Creates a valid GTFS-RT protobuf binary with a vehicle position entity.
    private func makeVehiclePositionFeedData() throws -> Data {
        var header = TransitRealtime_FeedHeader()
        header.gtfsRealtimeVersion = "2.0"
        header.timestamp = 1700000000

        var position = TransitRealtime_Position()
        position.latitude = 48.8566
        position.longitude = 2.3522
        position.bearing = 90.0
        position.speed = 15.5

        var vehicleDescriptor = TransitRealtime_VehicleDescriptor()
        vehicleDescriptor.id = "VEH_42"
        vehicleDescriptor.label = "Train 42"

        var tripDescriptor = TransitRealtime_TripDescriptor()
        tripDescriptor.tripID = "TRIP_2"

        var vehiclePosition = TransitRealtime_VehiclePosition()
        vehiclePosition.trip = tripDescriptor
        vehiclePosition.vehicle = vehicleDescriptor
        vehiclePosition.position = position
        vehiclePosition.currentStopSequence = 5
        vehiclePosition.stopID = "STOP_B"
        vehiclePosition.currentStatus = .inTransitTo
        vehiclePosition.timestamp = 1700000000
        vehiclePosition.congestionLevel = .runningSmoothly
        vehiclePosition.occupancyStatus = .manySeatsAvailable

        var entity = TransitRealtime_FeedEntity()
        entity.id = "entity_2"
        entity.vehicle = vehiclePosition

        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header = header
        feedMessage.entity = [entity]

        return try feedMessage.serializedData()
    }

    /// Creates a valid GTFS-RT protobuf binary with an alert entity.
    private func makeAlertFeedData() throws -> Data {
        var header = TransitRealtime_FeedHeader()
        header.gtfsRealtimeVersion = "2.0"
        header.timestamp = 1700000000

        var timeRange = TransitRealtime_TimeRange()
        timeRange.start = 1700000000
        timeRange.end = 1700086400

        var entitySelector = TransitRealtime_EntitySelector()
        entitySelector.routeID = "ROUTE_1"

        var headerTranslation = TransitRealtime_TranslatedString.Translation()
        headerTranslation.text = "Service perturbé"
        headerTranslation.language = "fr"

        var headerText = TransitRealtime_TranslatedString()
        headerText.translation = [headerTranslation]

        var descTranslation = TransitRealtime_TranslatedString.Translation()
        descTranslation.text = "Travaux sur la ligne"
        descTranslation.language = "fr"

        var descText = TransitRealtime_TranslatedString()
        descText.translation = [descTranslation]

        var alert = TransitRealtime_Alert()
        alert.activePeriod = [timeRange]
        alert.informedEntity = [entitySelector]
        alert.cause = .construction
        alert.effect = .significantDelays
        alert.headerText = headerText
        alert.descriptionText = descText
        alert.severityLevel = .warning

        var entity = TransitRealtime_FeedEntity()
        entity.id = "entity_3"
        entity.alert = alert

        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header = header
        feedMessage.entity = [entity]

        return try feedMessage.serializedData()
    }

    // MARK: - Trip Update Tests

    func testParseTripUpdate() throws {
        let data = try makeTripUpdateFeedData()
        let feed = try RealtimeFeed(data: data)

        XCTAssertEqual(feed.header.gtfsRealtimeVersion, "2.0")
        XCTAssertEqual(feed.header.incrementality, .fullDataset)
        XCTAssertNotNil(feed.header.timestamp)

        XCTAssertEqual(feed.tripUpdates.count, 1)
        XCTAssertEqual(feed.vehiclePositions.count, 0)
        XCTAssertEqual(feed.alerts.count, 0)

        let tripUpdate = feed.tripUpdates[0]
        XCTAssertEqual(tripUpdate.trip.tripID, "TRIP_1")
        XCTAssertEqual(tripUpdate.trip.routeID, "ROUTE_1")
        XCTAssertEqual(tripUpdate.trip.directionID, 0)
        XCTAssertEqual(tripUpdate.trip.startDate, "20231114")
        XCTAssertEqual(tripUpdate.delay, 120)

        XCTAssertEqual(tripUpdate.stopTimeUpdates.count, 1)
        let stu = tripUpdate.stopTimeUpdates[0]
        XCTAssertEqual(stu.stopSequence, 3)
        XCTAssertEqual(stu.stopID, "STOP_A")
        XCTAssertEqual(stu.scheduleRelationship, .scheduled)
        XCTAssertNotNil(stu.arrival)
        XCTAssertEqual(stu.arrival?.delay, 120)
    }

    // MARK: - Vehicle Position Tests

    func testParseVehiclePosition() throws {
        let data = try makeVehiclePositionFeedData()
        let feed = try RealtimeFeed(data: data)

        XCTAssertEqual(feed.vehiclePositions.count, 1)
        XCTAssertEqual(feed.tripUpdates.count, 0)
        XCTAssertEqual(feed.alerts.count, 0)

        let vp = feed.vehiclePositions[0]
        XCTAssertEqual(vp.trip?.tripID, "TRIP_2")
        XCTAssertEqual(vp.vehicle?.id, "VEH_42")
        XCTAssertEqual(vp.vehicle?.label, "Train 42")
        XCTAssertNotNil(vp.position)
        XCTAssertEqual(vp.position?.latitude ?? 0, 48.8566, accuracy: 0.001)
        XCTAssertEqual(vp.position?.longitude ?? 0, 2.3522, accuracy: 0.001)
        XCTAssertEqual(vp.position?.bearing, 90.0)
        XCTAssertEqual(vp.position?.speed, 15.5)
        XCTAssertEqual(vp.currentStopSequence, 5)
        XCTAssertEqual(vp.stopID, "STOP_B")
        XCTAssertEqual(vp.currentStatus, .inTransitTo)
        XCTAssertEqual(vp.congestionLevel, .runningSmoothly)
        XCTAssertEqual(vp.occupancyStatus, .manySeatsAvailable)
    }

    // MARK: - Alert Tests

    func testParseAlert() throws {
        let data = try makeAlertFeedData()
        let feed = try RealtimeFeed(data: data)

        XCTAssertEqual(feed.alerts.count, 1)
        XCTAssertEqual(feed.tripUpdates.count, 0)
        XCTAssertEqual(feed.vehiclePositions.count, 0)

        let alert = feed.alerts[0]
        XCTAssertEqual(alert.cause, .construction)
        XCTAssertEqual(alert.effect, .significantDelays)
        XCTAssertEqual(alert.severityLevel, .warning)

        XCTAssertEqual(alert.activePeriods.count, 1)
        XCTAssertNotNil(alert.activePeriods[0].start)
        XCTAssertNotNil(alert.activePeriods[0].end)

        XCTAssertEqual(alert.informedEntities.count, 1)
        XCTAssertEqual(alert.informedEntities[0].routeID, "ROUTE_1")

        XCTAssertEqual(alert.headerText?.text(forLanguage: "fr"), "Service perturbé")
        XCTAssertEqual(alert.descriptionText?.text(forLanguage: "fr"), "Travaux sur la ligne")
    }

    // MARK: - Mixed Feed Tests

    func testParseMixedFeed() throws {
        var header = TransitRealtime_FeedHeader()
        header.gtfsRealtimeVersion = "2.0"

        var tripDescriptor = TransitRealtime_TripDescriptor()
        tripDescriptor.tripID = "T1"
        var tripUpdate = TransitRealtime_TripUpdate()
        tripUpdate.trip = tripDescriptor

        var position = TransitRealtime_Position()
        position.latitude = 45.0
        position.longitude = 3.0
        var vehiclePos = TransitRealtime_VehiclePosition()
        vehiclePos.position = position

        var alertProto = TransitRealtime_Alert()
        alertProto.cause = .strike

        var entity1 = TransitRealtime_FeedEntity()
        entity1.id = "e1"
        entity1.tripUpdate = tripUpdate

        var entity2 = TransitRealtime_FeedEntity()
        entity2.id = "e2"
        entity2.vehicle = vehiclePos

        var entity3 = TransitRealtime_FeedEntity()
        entity3.id = "e3"
        entity3.alert = alertProto

        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header = header
        feedMessage.entity = [entity1, entity2, entity3]

        let data = try feedMessage.serializedData()
        let feed = try RealtimeFeed(data: data)

        XCTAssertEqual(feed.tripUpdates.count, 1)
        XCTAssertEqual(feed.vehiclePositions.count, 1)
        XCTAssertEqual(feed.alerts.count, 1)
        XCTAssertEqual(feed.alerts[0].cause, RTAlert.Cause.strike)
    }

    // MARK: - Error Tests

    func testInvalidProtobufThrows() {
        let invalidData = Data([0xFF, 0xFE, 0x00, 0x01])
        XCTAssertThrowsError(try RealtimeFeed(data: invalidData)) { error in
            XCTAssertTrue(error is LSError)
            XCTAssertEqual(error as? LSError, .invalidProtobuf)
        }
    }

    func testEmptyFeed() throws {
        var header = TransitRealtime_FeedHeader()
        header.gtfsRealtimeVersion = "2.0"

        var feedMessage = TransitRealtime_FeedMessage()
        feedMessage.header = header

        let data = try feedMessage.serializedData()
        let feed = try RealtimeFeed(data: data)

        XCTAssertEqual(feed.tripUpdates.count, 0)
        XCTAssertEqual(feed.vehiclePositions.count, 0)
        XCTAssertEqual(feed.alerts.count, 0)
        XCTAssertEqual(feed.header.gtfsRealtimeVersion, "2.0")
    }

    // MARK: - Shared Types Tests

    func testTranslatedStringLanguageFallback() {
        let ts = RTTranslatedString(translations: [
            .init(text: "Hello", language: "en"),
            .init(text: "Bonjour", language: "fr"),
            .init(text: "Default"),
        ])

        XCTAssertEqual(ts.text(forLanguage: "fr"), "Bonjour")
        XCTAssertEqual(ts.text(forLanguage: "en"), "Hello")
        XCTAssertEqual(ts.text(forLanguage: "de"), "Default")
        XCTAssertEqual(ts.text(), "Default")
    }

    func testTimeRangeContains() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 2000)
        let range = RTTimeRange(start: start, end: end)

        XCTAssertTrue(range.contains(Date(timeIntervalSince1970: 1500)))
        XCTAssertFalse(range.contains(Date(timeIntervalSince1970: 500)))
        XCTAssertFalse(range.contains(Date(timeIntervalSince1970: 2500)))

        let openRange = RTTimeRange(start: nil, end: nil)
        XCTAssertTrue(openRange.contains(Date()))
    }
}
