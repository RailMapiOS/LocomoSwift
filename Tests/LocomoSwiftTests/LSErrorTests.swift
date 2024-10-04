//
//  LSErrorTests.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 04/10/2024.
//

import XCTest
@testable import LocomoSwift

class LSErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(LSError.emptySubstring.localizedDescription, "Substring is empty")
        XCTAssertEqual(LSError.commaExpected.localizedDescription, "A comma was expected, but not found")
        XCTAssertEqual(LSError.quoteExpected.localizedDescription, "A quote was expected, but not found")
        XCTAssertEqual(LSError.invalidFieldType.localizedDescription, "An invalid field type was found")
        XCTAssertEqual(LSError.missingRequiredFields.localizedDescription, "One or more required fields is missing")
        XCTAssertEqual(LSError.headerRecordMismatch.localizedDescription, "The number of header and data fields are not the same")
        XCTAssertEqual(LSError.invalidColor.localizedDescription, "An invalid color was found")
        XCTAssertEqual(LSError.invalidURL.localizedDescription, "L'URL est invalide.")
        XCTAssertEqual(LSError.downloadFailed.localizedDescription, "Échec du téléchargement du fichier.")
        XCTAssertEqual(LSError.fileNotFound.localizedDescription, "Fichier temporaire introuvable.")
        XCTAssertEqual(LSError.extractionFailed.localizedDescription, "Échec de l'extraction de l'archive ZIP.")
    }
}
