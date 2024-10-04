//
//  FeedTests.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 04/10/2024.
//

import XCTest
@testable import LocomoSwift

class FeedTests: XCTestCase {
    
    /// Test pour vérifier que l'initialisation d'un Feed à partir d'un fichier ZIP local fonctionne correctement.
    func testFeedInitializationFromLocalZip() throws {
        // Accéder au bundle de test
        let bundle = Bundle.module
        
        // Récupérer l'URL du fichier ZIP à partir du bundle
        guard let zipURL = bundle.url(forResource: "export_gtfs_voyages", withExtension: "zip") else {
            XCTFail("Fichier ZIP introuvable dans les ressources de test.")
            return
        }
        
        // Test d'initialisation du feed à partir du fichier ZIP local
        let feed = try Feed(contentsOfURL: zipURL)
        XCTAssertNotNil(feed)
    }
    
    func testFeedInitializationFromInvalidRemoteURL() {
        let invalidURL = URL(string: "https://eu.ftp.opendatasoft.com/sncf/gtfs/export_gtfs_invalid.zip")!
        
        do {
            let _ = try Feed(contentsOfURL: invalidURL)
            XCTFail("L'initialisation aurait dû échouer pour une URL distante invalide.")
        } catch let error as LSError {
            XCTAssertEqual(error, .invalidFieldType, "L'erreur devrait être invalidFieldType en raison d'un problème avec les en-têtes.")
        } catch {
            XCTFail("Erreur inattendue: \(error)")
        }
    }
}
