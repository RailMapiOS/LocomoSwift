//
//  ErrorTests.swift
//  LocomoSwiftTests
//

import Foundation
import Testing
import LocomoSwift
import LocomoSwiftGTFS

@Suite("Errors")
struct ErrorTests {

    @Test("Each LSError case exposes a non-empty localized description")
    func lsErrorDescriptions() {
        let cases: [LSError] = [
            .emptySubstring, .commaExpected, .quoteExpected, .invalidFieldType,
            .missingRequiredFields, .headerRecordMismatch, .invalidColor,
            .invalidURL, .downloadFailed, .fileNotFound, .extractionFailed
        ]
        for c in cases {
            #expect(!(c.errorDescription ?? "").isEmpty)
        }
    }

    @Test("LSAssignError exposes localized descriptions for both cases")
    func lsAssignErrorDescriptions() {
        #expect(LSAssignError.invalidPath.errorDescription == "Path is invalid")
        #expect(LSAssignError.invalidValue.errorDescription == "Could not value convert to target type")
    }

    @Test("Each RealtimeError case exposes a non-empty localized description")
    func realtimeErrorDescriptions() {
        let cases: [RealtimeError] = [
            .networkError,
            .invalidData,
            .parsingError,
            .feedTypeNotAvailable(.tripUpdates),
            .staticFeedNotConfigured("test")
        ]
        for c in cases {
            #expect(!(c.errorDescription ?? "").isEmpty)
        }
    }
}
