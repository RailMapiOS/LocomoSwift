//
//  StringExtensionsTests.swift
//  LocomoSwiftTests
//

import Foundation
import Testing
import LocomoSwift
@testable import LocomoSwiftGTFS

@Suite("String Parsing Extensions")
struct StringExtensionsTests {

    @Test("readRecord parses comma-separated, quoted, and empty fields",
          arguments: [
            ("a,b,c", ["a", "b", "c"]),
            ("a,\"b,b\",c", ["a", "b,b", "c"]),
            ("a,,c", ["a", "", "c"]),
            ("a,b,", ["a", "b", ""])
          ])
    func readRecordVariants(input: String, expected: [String]) throws {
        #expect(try input.readRecord() == expected)
    }

    @Test("nextField throws quoteExpected when a quoted field is unterminated")
    func unterminatedQuoteThrows() {
        var sub: Substring = "\"unterminated"
        #expect(throws: LSError.self) { try sub.nextField() }
    }

    @Test("nextField throws commaExpected when a quote is not followed by a comma or end")
    func quoteWithoutCommaThrows() {
        var sub: Substring = "\"a\"b"
        #expect(throws: LSError.self) { try sub.nextField() }
    }

    @Test("hex strings convert to a non-nil CGColor",
          arguments: ["#FF0000", "00FF00", "#000000FF"])
    func validHexColors(hex: String) {
        #expect(hex.color != nil)
    }

    @Test("invalid hex strings convert to nil",
          arguments: ["", "ZZZZZZ", "#GG00FF", "12345"])
    func invalidHexColors(hex: String) {
        #expect(hex.color == nil)
    }
}
