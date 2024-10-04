//
//  StringExtTests.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 04/10/2024.
//

import XCTest
import MapKit
@testable import LocomoSwift


class StringExtensionsTests: XCTestCase {
    
    //MARK: -Test pour nextField() dans Substring
    
    func testNextFieldWithQuotedField() throws {
        var input: Substring = "\"quoted field\",next"
        let field = try input.nextField()
        XCTAssertEqual(field, "quoted field")
        XCTAssertEqual(input, "next")
    }
    
    func testNextFieldWithComma() throws {
        var input: Substring = "field1,field2"
        let field = try input.nextField()
        XCTAssertEqual(field, "field1")
        XCTAssertEqual(input, "field2")
    }
    
    func testNextFieldWithEmptyField() throws {
        var input: Substring = ",field2"
        let field = try input.nextField()
        XCTAssertEqual(field, "")
        XCTAssertEqual(input, "field2")
    }
    
    func testNextFieldWithUnterminatedQuotedField() {
        var input: Substring = "\"unterminated field"
        XCTAssertThrowsError(try input.nextField()) { error in
            XCTAssertEqual(error as? LSError, LSError.quoteExpected)
        }
    }
    
    func testNextFieldWithCommaExpectedAfterQuotedField() {
        var input: Substring = "\"field\"field2"
        XCTAssertThrowsError(try input.nextField()) { error in
            XCTAssertEqual(error as? LSError, LSError.commaExpected)
        }
    }
    
    //MARK: Test pour readRecord() dans String
    func testReadRecord() throws {
        let input = "field1,\"quoted field\",field3"
        let result = try input.readRecord()
        XCTAssertEqual(result, ["field1", "quoted field", "field3"])
    }
    
    func testReadRecordWithEmptyField() throws {
        let input = "field1,,field3"
        let result = try input.readRecord()
        XCTAssertEqual(result, ["field1", "", "field3"])
    }
    
    func testReadRecordWithTrailingComma() throws {
        let input = "field1,field2,"
        let result = try input.readRecord()
        XCTAssertEqual(result, ["field1", "field2", ""])
    }
    
    //MARK: -Test pour splitRecords() dans String
    
    func testSplitRecords() {
        let input = "record1\nrecord2\r\nrecord3\rrecord4"
        let result = input.splitRecords()
        XCTAssertEqual(result, ["record1", "record2", "record3", "record4"])
    }
    
    //MARK: -Test pour color dans String
    
    func testColorWithValidHex() {
        let colorString = "#FF0000"
        let color = colorString.color
        XCTAssertNotNil(color)
    }
    
    func testColorWithInvalidHex() {
        let colorString = "ZZZZZZ"
        let color = colorString.color
        XCTAssertNil(color)
    }
    
    func testColorWithSixHex() {
        let colorString = "#00FF00"
        let color = colorString.color
        XCTAssertNotNil(color)
    }
    
    //MARK: -Tests pour readHeader()
    
    enum GTFSField: String {
        case field1, field2
    }
    
    func testReadHeader() throws {
        let input = "field1,field2,unknown"
        
        do {
            let result: [GTFSField] = try input.readHeader()
            XCTFail("L'initialisation aurait dû échouer avec un champ d'en-tête non valide.")
        } catch let error as LSError {
            XCTAssertEqual(error, .invalidFieldType, "L'erreur devrait être invalidFieldType pour le champ d'en-tête non reconnu.")
        } catch {
            XCTFail("Erreur inattendue: \(error)")
        }
    }
    
    func testReadHeaderWithValidFields() throws {
        let input = "field1,field2"
        let result: [GTFSField] = try input.readHeader()
        XCTAssertEqual(result, [.field1, .field2], "Les champs d'en-tête devraient correspondre aux valeurs valides.")
    }
    
    //MARK: -Tests pour assignStringTo
    struct MockInstance {
        var field: String = ""
    }
    
    func testAssignStringTo() throws {
        var instance = MockInstance()
        let input = "newValue"
        try input.assignStringTo(&instance, for: MockField.stringField)
        XCTAssertEqual(instance.field, "newValue")
    }
    
    //MARK: -Tests pour assignOptionalStringTo
    
    struct MockOptionalInstance {
        var field: String? = nil
    }
    
    func testAssignOptionalStringTo() throws {
        var instance = MockOptionalInstance()
        let input = "newValue"
        try input.assignOptionalStringTo(&instance, for: MockField.optionalStringField)
        XCTAssertEqual(instance.field, "newValue")
        
        let emptyInput = ""
        try emptyInput.assignOptionalStringTo(&instance, for: MockField.optionalStringField)
        XCTAssertNil(instance.field)
    }
    
    //MARK: -Tests pour assignUIntTo et assignOptionalUIntTo
    
    struct MockUIntInstance {
        var field: UInt = 0
    }
    
    func testAssignUIntTo() throws {
        var instance = MockUIntInstance()
        let input = "42"
        try input.assignUIntTo(&instance, for: MockField.uintField)
        XCTAssertEqual(instance.field, 42)
    }
    
    struct MockOptionalUIntInstance {
        var field: UInt? = nil
    }
    
    func testAssignOptionalUIntTo() throws {
        var instance = MockOptionalUIntInstance()
        let input = "42"
        try input.assignOptionalUIntTo(&instance, for: MockField.optionalUIntField)
        XCTAssertEqual(instance.field, 42)
        
        let emptyInput = ""
        try emptyInput.assignOptionalUIntTo(&instance, for: MockField.optionalUIntField)
        XCTAssertNil(instance.field)
    }
    
    //MARK: -Tests pour assignURLValueTo et assignOptionalURLTo
    
    struct MockURLInstance {
        var field: URL = URL(string: "http://default.com")!
    }
    
    func testAssignURLValueTo() throws {
        var instance = MockURLInstance()
        let input = "https://example.com"
        try input.assignURLValueTo(&instance, for: MockField.urlField)
        XCTAssertEqual(instance.field, URL(string: "https://example.com")!)
    }
    
    struct MockOptionalURLInstance {
        var field: URL? = nil
    }
    
    func testAssignOptionalURLTo() throws {
        var instance = MockOptionalURLInstance()
        let input = "https://example.com"
        try input.assignOptionalURLTo(&instance, for: MockField.optionalURLField)
        XCTAssertEqual(instance.field, URL(string: "https://example.com")!)
        
        let emptyInput = ""
        try emptyInput.assignOptionalURLTo(&instance, for: MockField.optionalURLField)
        XCTAssertNil(instance.field)
    }
    
    //MARK: -Tests pour assignTimeZoneTo et assignOptionalTimeZoneTo
    
    struct MockTimeZoneInstance {
        var field: TimeZone = TimeZone.current
    }
    
    func testAssignTimeZoneTo() throws {
        var instance = MockTimeZoneInstance()
        let input = "America/New_York"
        try input.assignTimeZoneTo(&instance, for: MockField.timeZoneField)
        XCTAssertEqual(instance.field.identifier, "America/New_York")
    }
    
    struct MockOptionalTimeZoneInstance {
        var field: TimeZone? = nil
    }
    
    func testAssignOptionalTimeZoneTo() throws {
        var instance = MockOptionalTimeZoneInstance()
        let input = "America/New_York"
        try input.assignOptionalTimeZoneTo(&instance, for: MockField.optionalTimeZoneField)
        XCTAssertEqual(instance.field?.identifier, "America/New_York")
        
        let emptyInput = ""
        try emptyInput.assignOptionalTimeZoneTo(&instance, for: MockField.optionalTimeZoneField)
        XCTAssertNil(instance.field)
    }
    
    //MARK: -Tests pour assignOptionalCGColorTo
    
    struct MockCGColorInstance {
        var field: CGColor? = nil
    }
    
    func testAssignOptionalCGColorTo() throws {
        var instance = MockCGColorInstance()
        let input = "#FF0000"
        try input.assignOptionalCGColorTo(&instance, for: MockField.cgColorField)
        XCTAssertNotNil(instance.field)
        
        let emptyInput = ""
        try emptyInput.assignOptionalCGColorTo(&instance, for: MockField.cgColorField)
        XCTAssertNil(instance.field)
    }
    
    //MARK: -Tests pour assignOptionalCLLocationDegreesTo
    
    struct MockCLLocationDegreesInstance {
        var field: CLLocationDegrees? = nil
    }
    
    func testAssignOptionalCLLocationDegreesTo() throws {
        var instance = MockCLLocationDegreesInstance()
        
        // Test valid value
        let input = "45.1234"
        try input.assignOptionalCLLocationDegreesTo(&instance, for: MockField(path: \MockCLLocationDegreesInstance.field))
        XCTAssertEqual(instance.field, 45.1234)
        
        // Test empty value
        let emptyInput = ""
        try emptyInput.assignOptionalCLLocationDegreesTo(&instance, for: MockField(path: \MockCLLocationDegreesInstance.field))
        XCTAssertNil(instance.field)
        
        // Test invalid value
        let invalidInput = "invalid"
        XCTAssertThrowsError(try invalidInput.assignOptionalCLLocationDegreesTo(&instance, for: MockField(path: \MockCLLocationDegreesInstance.field))) { error in
            XCTAssertEqual(error as? LSAssignError, LSAssignError.invalidValue)
        }
    }
    
    //MARK: -Tests pour assignLocaleTo
    
    struct MockLocaleInstance {
        var field: Locale? = nil
    }
    
    func testAssignLocaleTo() throws {
        var instance = MockLocaleInstance()

        // Test valid locale
        let input = "fr_FR"
        try input.assignLocaleTo(&instance, for: MockField(path: \MockLocaleInstance.field))
        XCTAssertEqual(instance.field?.identifier, "fr_FR")

        // Test empty value
        let emptyInput = ""
        try emptyInput.assignLocaleTo(&instance, for: MockField(path: \MockLocaleInstance.field))
        XCTAssertNil(instance.field, "Expected the field to be nil when the input is an empty string.")
    }

    //MARK: -Tests pour assignRouteTypeTo
    
    enum RouteType: String {
        case bus = "bus"
        case train = "train"
        case unknown = "unknown"
    }
    
    struct MockRouteTypeInstance {
        var field: RouteType = .unknown
    }
    
//    func testAssignRouteTypeTo() throws {
//        var instance = MockRouteTypeInstance()
//        
//        // Test valid route type
//        let input = "bus"
//        try input.assignRouteTypeTo(&instance, for: MockField.routeTypeField)
//        XCTAssertEqual(instance.field, .bus)
//        
//        // Test invalid route type
//        let invalidInput = "invalid"
//        XCTAssertThrowsError(try invalidInput.assignRouteTypeTo(&instance, for: MockField.routeTypeField)) { error in
//            XCTAssertEqual(error as? LSAssignError, LSAssignError.invalidValue)
//        }
//    }
    
    //MARK: -Tests pour assignOptionalPickupDropOffPolicyTo
    
    enum PickupDropOffPolicy: String {
        case allowed = "allowed"
        case notAllowed = "notAllowed"
    }
    
    struct Route {
        static func pickupDropOffPolicyFrom(string: String) -> PickupDropOffPolicy? {
            switch string {
            case "allowed":
                return .allowed
            case "notAllowed":
                return .notAllowed
            default:
                return nil
            }
        }
        
        static func routeTypeFrom(string: String) -> RouteType? {
            switch string {
            case "bus":
                return .bus
            case "train":
                return .train
            default:
                return nil
            }
        }
    }
    
    struct MockPickupDropOffPolicyInstance {
        var field: PickupDropOffPolicy? = nil
    }
    
//    func testAssignOptionalPickupDropOffPolicyTo() throws {
//        var instance = MockPickupDropOffPolicyInstance()
//        
//        // Test valid policy
//        let input = "allowed"
//        try input.assignOptionalPickupDropOffPolicyTo(&instance, for: MockField.pickupDropOffPolicyField)
//        XCTAssertEqual(instance.field, .allowed)
//        
//        // Test invalid policy
//        let invalidInput = "invalid"
//        XCTAssertThrowsError(try invalidInput.assignOptionalPickupDropOffPolicyTo(&instance, for: MockField.pickupDropOffPolicyField)) { error in
//            XCTAssertEqual(error as? LSAssignError, LSAssignError.invalidValue)
//        }
//        
//        // Test empty value
//        let emptyInput = ""
//        try emptyInput.assignOptionalPickupDropOffPolicyTo(&instance, for: MockField.pickupDropOffPolicyField)
//        XCTAssertNil(instance.field)
//    }
    
    //MARK: -MockField: KeyPathVending
    
    struct MockField: KeyPathVending {
        var path: AnyKeyPath
        
        static var stringField: MockField {
            return MockField(path: \MockInstance.field)
        }
        
        static var optionalStringField: MockField {
            return MockField(path: \MockOptionalInstance.field)
        }
        
        static var uintField: MockField {
            return MockField(path: \MockUIntInstance.field)
        }
        
        static var optionalUIntField: MockField {
            return MockField(path: \MockOptionalUIntInstance.field)
        }
        
        static var urlField: MockField {
            return MockField(path: \MockURLInstance.field)
        }
        
        static var optionalURLField: MockField {
            return MockField(path: \MockOptionalURLInstance.field)
        }
        
        static var timeZoneField: MockField {
            return MockField(path: \MockTimeZoneInstance.field)
        }
        
        static var optionalTimeZoneField: MockField {
            return MockField(path: \MockOptionalTimeZoneInstance.field)
        }
        
        static var cgColorField: MockField {
            return MockField(path: \MockCGColorInstance.field)
        }
        
        static var routeTypeField: MockField {
            return MockField(path: \MockRouteTypeInstance.field)
        }
        
        static var pickupDropOffPolicyField: MockField {
            return MockField(path: \MockPickupDropOffPolicyInstance.field)
        }
    }
}
