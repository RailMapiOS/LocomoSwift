//
//  RealtimeFullCoverageTests.swift
//  LocomoSwiftTests
//
//  Coverage for the GTFS-RT fields exposed in 1.2.0:
//  TripDescriptor, VehicleDescriptor, TripProperties, StopTimeProperties,
//  StopTimeEvent uncertainty / scheduledTime, occupancy, congestion,
//  multi-carriage, severity, TranslatedString/TranslatedImage,
//  FeedHeader and the unified RealtimeFeed pipeline.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
import LocomoSwift
import LocomoSwiftGTFS
@testable import LocomoSwiftRT

@Suite("Realtime Full Coverage", .serialized)
struct RealtimeFullCoverageTests {

    // MARK: - Fixture builder

    /// A FeedMessage exercising every field LocomoSwiftRT now exposes.
    private static func makeRichFeedMessage() -> TransitRealtime_FeedMessage {
        var feed = TransitRealtime_FeedMessage()

        // Header
        feed.header.gtfsRealtimeVersion = "2.0"
        feed.header.timestamp = 1_700_000_000
        feed.header.incrementality = .differential
        feed.header.feedVersion = "abc-123"

        // ----- TripUpdate entity -----
        var trip = TransitRealtime_TripDescriptor()
        trip.tripID = "T1"
        trip.routeID = "R1"
        trip.directionID = 1
        trip.startDate = "20260601"
        trip.startTime = "08:00:00"
        trip.scheduleRelationship = .duplicated

        var vehicle = TransitRealtime_VehicleDescriptor()
        vehicle.id = "V42"
        vehicle.label = "Coach 7712"
        vehicle.licensePlate = "AB-123-CD"
        vehicle.wheelchairAccessible = .wheelchairAccessible

        var arrival = TransitRealtime_TripUpdate.StopTimeEvent()
        arrival.delay = 60
        arrival.time = 1_700_000_120
        arrival.uncertainty = 30
        arrival.scheduledTime = 1_700_000_100

        var departure = TransitRealtime_TripUpdate.StopTimeEvent()
        departure.delay = 90
        departure.time = 1_700_000_180

        var stopTimeProperties = TransitRealtime_TripUpdate.StopTimeUpdate.StopTimeProperties()
        stopTimeProperties.assignedStopID = "S2-platform-B"
        stopTimeProperties.stopHeadsign = "via Saint-Lazare"
        stopTimeProperties.pickupType = .phoneAgency
        stopTimeProperties.dropOffType = .none

        var stopTimeUpdate = TransitRealtime_TripUpdate.StopTimeUpdate()
        stopTimeUpdate.stopID = "S2"
        stopTimeUpdate.stopSequence = 2
        stopTimeUpdate.arrival = arrival
        stopTimeUpdate.departure = departure
        stopTimeUpdate.scheduleRelationship = .skipped
        stopTimeUpdate.departureOccupancyStatus = .standingRoomOnly
        stopTimeUpdate.stopTimeProperties = stopTimeProperties

        var tripProperties = TransitRealtime_TripUpdate.TripProperties()
        tripProperties.tripID = "T1-DUP"
        tripProperties.startDate = "20260602"
        tripProperties.startTime = "10:30:00"
        tripProperties.shapeID = "SHAPE-DETOUR"
        tripProperties.tripHeadsign = "via détour"
        tripProperties.tripShortName = "TGV-DUP"

        var tripUpdate = TransitRealtime_TripUpdate()
        tripUpdate.trip = trip
        tripUpdate.vehicle = vehicle
        tripUpdate.stopTimeUpdate = [stopTimeUpdate]
        tripUpdate.timestamp = 1_700_000_000
        tripUpdate.delay = 60
        tripUpdate.tripProperties = tripProperties

        var entity1 = TransitRealtime_FeedEntity()
        entity1.id = "trip-T1"
        entity1.tripUpdate = tripUpdate

        // ----- VehiclePosition entity (with multi-carriage) -----
        var position = TransitRealtime_Position()
        position.latitude = 48.85
        position.longitude = 2.30
        position.bearing = 90
        position.odometer = 12345.678
        position.speed = 25.5

        var carriage1 = TransitRealtime_VehiclePosition.CarriageDetails()
        carriage1.id = "c1"
        carriage1.label = "Voiture 1"
        carriage1.occupancyStatus = .manySeatsAvailable
        carriage1.occupancyPercentage = 30
        carriage1.carriageSequence = 1

        var carriage2 = TransitRealtime_VehiclePosition.CarriageDetails()
        carriage2.id = "c2"
        carriage2.label = "Voiture 2"
        carriage2.occupancyStatus = .full
        carriage2.occupancyPercentage = 95
        carriage2.carriageSequence = 2

        var carriage3 = TransitRealtime_VehiclePosition.CarriageDetails()
        // No occupancyPercentage set — wire defaults to -1, should map to nil.
        carriage3.id = "c3"
        carriage3.carriageSequence = 3
        carriage3.occupancyStatus = .noDataAvailable

        var vehiclePosition = TransitRealtime_VehiclePosition()
        vehiclePosition.trip = trip
        vehiclePosition.vehicle = vehicle
        vehiclePosition.position = position
        vehiclePosition.currentStopSequence = 2
        vehiclePosition.stopID = "S2"
        vehiclePosition.currentStatus = .stoppedAt
        vehiclePosition.timestamp = 1_700_000_010
        vehiclePosition.congestionLevel = .stopAndGo
        vehiclePosition.occupancyStatus = .fewSeatsAvailable
        vehiclePosition.occupancyPercentage = 75
        vehiclePosition.multiCarriageDetails = [carriage1, carriage2, carriage3]

        var entity2 = TransitRealtime_FeedEntity()
        entity2.id = "vehicle-V42"
        entity2.vehicle = vehiclePosition

        // ----- Service Alert entity -----
        var headerText = TransitRealtime_TranslatedString()
        var headerFR = TransitRealtime_TranslatedString.Translation()
        headerFR.text = "Travaux en gare"
        headerFR.language = "fr"
        var headerEN = TransitRealtime_TranslatedString.Translation()
        headerEN.text = "Station works"
        headerEN.language = "en"
        headerText.translation = [headerFR, headerEN]

        var causeDetail = TransitRealtime_TranslatedString()
        var causeDetailFR = TransitRealtime_TranslatedString.Translation()
        causeDetailFR.text = "Renouvellement des voies"
        causeDetailFR.language = "fr"
        causeDetail.translation = [causeDetailFR]

        var ttsHeaderText = TransitRealtime_TranslatedString()
        var ttsTranslation = TransitRealtime_TranslatedString.Translation()
        ttsTranslation.text = "Travaux en gare"
        ttsTranslation.language = "fr"
        ttsHeaderText.translation = [ttsTranslation]

        var imageURL = TransitRealtime_TranslatedImage.LocalizedImage()
        imageURL.url = "https://example.com/alert.png"
        imageURL.mediaType = "image/png"
        imageURL.language = "fr"
        var image = TransitRealtime_TranslatedImage()
        image.localizedImage = [imageURL]

        var activePeriod = TransitRealtime_TimeRange()
        activePeriod.start = 1_700_000_000
        activePeriod.end = 1_700_010_000

        var informedTrip = TransitRealtime_TripDescriptor()
        informedTrip.tripID = "T1"
        informedTrip.routeID = "R1"
        var informed = TransitRealtime_EntitySelector()
        informed.routeID = "R1"
        informed.routeType = 2
        informed.directionID = 1
        informed.trip = informedTrip

        var alert = TransitRealtime_Alert()
        alert.cause = .construction
        alert.effect = .reducedService
        alert.severityLevel = .warning
        alert.headerText = headerText
        alert.causeDetail = causeDetail
        alert.ttsHeaderText = ttsHeaderText
        alert.image = image
        alert.activePeriod = [activePeriod]
        alert.informedEntity = [informed]

        var entity3 = TransitRealtime_FeedEntity()
        entity3.id = "alert-construction-1"
        entity3.alert = alert

        // ----- Realtime Shape entity -----
        var rtShape = TransitRealtime_Shape()
        rtShape.shapeID = "DETOUR-1"
        rtShape.encodedPolyline = "_p~iF~ps|U_ulLnnqC"
        var entity4 = TransitRealtime_FeedEntity()
        entity4.id = "shape-DETOUR-1"
        entity4.shape = rtShape

        // ----- Deleted entity (DIFFERENTIAL marker) -----
        var entity5 = TransitRealtime_FeedEntity()
        entity5.id = "vehicle-removed-X"
        entity5.isDeleted = true

        feed.entity = [entity1, entity2, entity3, entity4, entity5]
        return feed
    }

    // MARK: - FeedHeader

    @Test("RealtimeFeedHeader exposes version, incrementality, timestamp, and feed_version from the FeedMessage header")
    func decodesFeedHeader() throws {
        let proto = Self.makeRichFeedMessage()
        let feed = FeedMessageMapper.map(proto)

        #expect(feed.header.gtfsRealtimeVersion == "2.0")
        #expect(feed.header.incrementality == .differential)
        #expect(feed.header.feedVersion == "abc-123")
        let ts = try #require(feed.header.timestamp)
        #expect(ts == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test("FeedMessageMapper splits entities into trip updates, vehicle positions, alerts, shapes, and tracks deleted IDs")
    func splitsEntitiesAcrossKinds() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())

        #expect(feed.tripUpdates.count == 1)
        #expect(feed.vehiclePositions.count == 1)
        #expect(feed.serviceAlerts.count == 1)
        #expect(feed.shapes.count == 1)
        #expect(feed.deletedEntityIDs == ["vehicle-removed-X"])
    }

    // MARK: - TripUpdate richness

    @Test("RealtimeTripUpdate exposes the full TripDescriptor (route, direction, dates, schedule relationship)")
    func decodesTripDescriptor() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let update = try #require(feed.tripUpdates.first)

        #expect(update.trip.tripID == "T1")
        #expect(update.trip.routeID == "R1")
        #expect(update.trip.directionID == 1)
        #expect(update.trip.startDate == "20260601")
        #expect(update.trip.startTime == "08:00:00")
        #expect(update.trip.scheduleRelationship == .duplicated)
    }

    @Test("RealtimeTripUpdate exposes the VehicleDescriptor with label, plate, and wheelchair accessibility")
    func decodesVehicleDescriptor() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let update = try #require(feed.tripUpdates.first)
        let vehicle = try #require(update.vehicle)

        #expect(vehicle.id == "V42")
        #expect(vehicle.label == "Coach 7712")
        #expect(vehicle.licensePlate == "AB-123-CD")
        #expect(vehicle.wheelchairAccessible == .accessible)
    }

    @Test("RealtimeTripProperties exposes shape_id, headsign, short name, and start date/time for DUPLICATED trips")
    func decodesTripProperties() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let update = try #require(feed.tripUpdates.first)
        let properties = try #require(update.tripProperties)

        #expect(properties.tripID == "T1-DUP")
        #expect(properties.startDate == "20260602")
        #expect(properties.startTime == "10:30:00")
        #expect(properties.shapeID == "SHAPE-DETOUR")
        #expect(properties.tripHeadsign == "via détour")
        #expect(properties.tripShortName == "TGV-DUP")
    }

    @Test("StopTimeEvent exposes uncertainty and scheduledTime")
    func decodesStopTimeEventExtras() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let stu = try #require(feed.tripUpdates.first?.stopTimeUpdates.first)
        let arrival = try #require(stu.arrival)

        #expect(arrival.uncertainty == 30)
        #expect(arrival.scheduledTime == Date(timeIntervalSince1970: 1_700_000_100))
        #expect(stu.departureOccupancyStatus == .standingRoomOnly)
    }

    @Test("RealtimeStopTimeProperties exposes assignedStopID, headsign, and pickup/drop-off types")
    func decodesStopTimeProperties() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let stu = try #require(feed.tripUpdates.first?.stopTimeUpdates.first)
        let properties = try #require(stu.stopTimeProperties)

        #expect(properties.assignedStopID == "S2-platform-B")
        #expect(properties.stopHeadsign == "via Saint-Lazare")
        #expect(properties.pickupType == .phoneAgency)
        #expect(properties.dropOffType == DropOffPickupType.none)
        #expect(stu.scheduleRelationship == .skipped)
    }

    // MARK: - VehiclePosition richness

    @Test("RealtimeVehiclePosition exposes congestion, occupancy percentage, current status, stopID, and odometer")
    func decodesVehiclePositionExtras() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let position = try #require(feed.vehiclePositions.first)

        #expect(position.congestionLevel == .stopAndGo)
        #expect(position.occupancyStatus == .fewSeatsAvailable)
        #expect(position.occupancyPercentage == 75)
        #expect(position.currentStatus == .stoppedAt)
        #expect(position.stopID == "S2")
        #expect(position.odometer == 12345.678)
    }

    @Test("RealtimeVehiclePosition decodes per-carriage details and treats wire occupancyPercentage = -1 as nil")
    func decodesMultiCarriageDetails() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let position = try #require(feed.vehiclePositions.first)

        #expect(position.multiCarriageDetails.count == 3)
        let c1 = position.multiCarriageDetails[0]
        let c2 = position.multiCarriageDetails[1]
        let c3 = position.multiCarriageDetails[2]

        #expect(c1.carriageSequence == 1)
        #expect(c1.occupancyStatus == .manySeatsAvailable)
        #expect(c1.occupancyPercentage == 30)

        #expect(c2.occupancyStatus == .full)
        #expect(c2.occupancyPercentage == 95)

        #expect(c3.occupancyPercentage == nil)  // wire was -1
        #expect(c3.occupancyStatus == .noDataAvailable)
    }

    // MARK: - Alerts

    @Test("RealtimeServiceAlert exposes severity, cause/effect detail, TTS variants, and translated images")
    func decodesAlertRichFields() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let alert = try #require(feed.serviceAlerts.first)

        #expect(alert.severityLevel == .warning)
        #expect(alert.cause == .construction)
        #expect(alert.effect == .reducedService)

        let causeDetail = try #require(alert.causeDetail)
        #expect(causeDetail.text(for: Locale(identifier: "fr_FR")) == "Renouvellement des voies")

        let tts = try #require(alert.ttsHeaderText)
        #expect(tts.allTexts == ["Travaux en gare"])

        let image = try #require(alert.image)
        let firstImage = try #require(image.image(for: Locale(identifier: "fr_FR")))
        #expect(firstImage.url.absoluteString == "https://example.com/alert.png")
        #expect(firstImage.mediaType == "image/png")
    }

    @Test("AlertInformedEntity preserves the embedded TripDescriptor and direction info")
    func informedEntityHasTrip() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let alert = try #require(feed.serviceAlerts.first)
        let informed = try #require(alert.informedEntities.first)

        #expect(informed.routeID == "R1")
        #expect(informed.routeType == 2)
        #expect(informed.directionID == 1)
        #expect(informed.trip?.tripID == "T1")
        #expect(informed.tripID == "T1")  // convenience accessor
    }

    @Test("RealtimeServiceAlert.isActive(at:) honours active periods")
    func alertActivityWindow() throws {
        let feed = FeedMessageMapper.map(Self.makeRichFeedMessage())
        let alert = try #require(feed.serviceAlerts.first)

        #expect(alert.isActive(at: Date(timeIntervalSince1970: 1_700_005_000)))
        #expect(!alert.isActive(at: Date(timeIntervalSince1970: 1_699_999_000)))
        #expect(!alert.isActive(at: Date(timeIntervalSince1970: 1_700_020_000)))
    }

    // MARK: - TranslatedString resolution

    @Test("TranslatedString.text(for:) prefers an exact match, then a primary-language match, then untagged")
    func translatedStringResolution() {
        let mixed = TranslatedString(translations: [
            .init(text: "Hello", language: "en"),
            .init(text: "Salut", language: "fr-FR"),
            .init(text: "Hola"),
        ])
        #expect(mixed.text(for: Locale(identifier: "fr_FR")) == "Salut")  // exact-ish via primary
        #expect(mixed.text(for: Locale(identifier: "en_GB")) == "Hello")  // primary match
        #expect(mixed.text(for: Locale(identifier: "de_DE")) == "Hola")   // untagged fallback
    }

    // MARK: - Enum extensibility

    @Test("Unknown enum raw values are preserved via .unrecognized rather than dropped",
          arguments: [42, 99, -1])
    func unknownEnumRawValuesArePreserved(rawValue: Int) {
        let cause = AlertCause(rawValue: rawValue)
        if case .unrecognized(let raw) = cause {
            #expect(raw == rawValue)
        } else {
            Issue.record("Expected .unrecognized for raw \(rawValue), got \(cause)")
        }

        // Round-trip through rawValue.
        #expect(cause.rawValue == rawValue)
    }

    // MARK: - RealtimeManager.fetchFeed via mock URLSession

    @Test("RealtimeManager.fetchFeed returns a fully populated RealtimeFeed via the injected session and decoder")
    func managerFetchesEntireFeed() async throws {
        let bytes = try Self.makeRichFeedMessage().serializedBytes() as Data
        let session = MockURLProtocol.makeSession()
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, bytes)
        }
        defer { MockURLProtocol.reset() }

        let manager = RealtimeManager(urlSession: session)
        let source = DataSource(
            identifier: "rich-mock",
            displayName: "Rich Mock",
            realtimeFeeds: [.tripUpdates: URL(string: "https://example.com/rt")!]
        )

        let feed = try await manager.fetchFeed(from: source, feedType: .tripUpdates)
        #expect(feed.tripUpdates.count == 1)
        #expect(feed.vehiclePositions.count == 1)
        #expect(feed.serviceAlerts.count == 1)
        #expect(feed.shapes.count == 1)
        #expect(feed.header.gtfsRealtimeVersion == "2.0")
    }

    @Test("ProtobufFeedMessageDecoder.decode throws RealtimeError.parsingError for malformed bytes")
    func protobufDecoderThrowsOnGarbage() throws {
        let decoder = ProtobufFeedMessageDecoder()
        #expect(throws: RealtimeError.self) {
            _ = try decoder.decode(Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
        }
    }
}
