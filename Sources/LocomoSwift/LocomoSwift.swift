// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  LocomoSwift.swift
//
//  Created by Jérémie Patot on 20/09/2024.
//

import Foundation
import ZIPFoundation

/// - Tag: LSID
public typealias LSID = String

/// - Tag: KeyPathVending
internal protocol KeyPathVending {
    var path: AnyKeyPath { get }
}

/// - Tag: LSError
public enum LSError: Error {
    case emptySubstring
    case commaExpected
    case quoteExpected
    case invalidFieldType
    case missingRequiredFields
    case headerRecordMismatch
    case invalidColor
    case invalidURL
    case downloadFailed
    case fileNotFound
    case extractionFailed
}

extension LSError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptySubstring:
            return "Substring is empty"
        case .commaExpected:
            return "A comma was expected, but not found"
        case .quoteExpected:
            return "A quote was expected, but not found"
        case .invalidFieldType:
            return "An invalid field type was found"
        case .missingRequiredFields:
            return "One or more required fields is missing"
        case .headerRecordMismatch:
            return "The number of header and data fields are not the same"
        case .invalidColor:
            return "An invalid color was found"
        case .invalidURL:
            return "L'URL est invalide."
        case .downloadFailed:
            return "Échec du téléchargement du fichier."
        case .fileNotFound:
            return "Fichier temporaire introuvable."
        case .extractionFailed:
            return "Échec de l'extraction de l'archive ZIP."
        }
    }
}

/// - Tag: LSAssignError
public enum LSAssignError: Error {
    case invalidPath
    case invalidValue
}

extension LSAssignError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "Path is invalid"
        case .invalidValue:
            return "Could not value convert to target type"
        }
    }
}

/// - Tag: LSSomethingError
public enum LSSomethingError: Error {
    case noDataRecordsFound
}

/// - Tag: Feed
public struct Feed: Identifiable {
    public let id = UUID()
    public var agencies: Agencies?
    public var routes: Routes?
    public var stops: Stops?
    public var trips: Trips?
    public var stopTimes: StopTimes?
    public var calendarDates: CalendarDates?
    
    public var agency: Agency? {
        return agencies?.first
    }
    
    private init() {
        self.agencies = nil
        self.routes = nil
        self.stops = nil
        self.trips = nil
        self.stopTimes = nil
        self.calendarDates = nil
    }
    
    public init(contentsOfURL url: URL) throws {
           let fileManager = FileManager.default
           var directoryURL: URL = url
           
           // Si l'URL est un fichier ZIP distant, télécharger puis extraire
           if url.pathExtension == "zip" {
               print("Fichier ZIP détecté, tentative de téléchargement et extraction.")
               
               if url.isFileURL {
                   // Si c'est un fichier local .zip, l'extraire directement
                   let tempDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                   try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                   try fileManager.unzipItem(at: url, to: tempDirectoryURL)
                   print("Extraction réussie dans le répertoire : \(tempDirectoryURL.path)")
                   directoryURL = tempDirectoryURL
               } else {
                   // Si c'est une URL distante, télécharger le fichier
                   let tempDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                   try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                   
                   // Télécharger le fichier ZIP
                   let tempFileURL = tempDirectoryURL.appendingPathComponent("export_gtfs_voyages.zip")
                   let (downloadedFileURL, response) = try URLSession.shared.downloadTaskSync(with: url)
                   
                   guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                       throw LSError.downloadFailed
                   }
                   
                   // Déplacer le fichier téléchargé dans le répertoire temporaire
                   try fileManager.moveItem(at: downloadedFileURL, to: tempFileURL)
                   
                   // Extraire le fichier ZIP
                   try fileManager.unzipItem(at: tempFileURL, to: tempDirectoryURL)
                   print("Extraction réussie dans le répertoire : \(tempDirectoryURL.path)")
                   directoryURL = tempDirectoryURL
               }
           }

           // Assumer que les fichiers nécessaires se trouvent dans le répertoire final (extrait ou original)
           let agencyFileURL = directoryURL.appendingPathComponent("agency.txt")
           let routesFileURL = directoryURL.appendingPathComponent("routes.txt")
           let stopsFileURL = directoryURL.appendingPathComponent("stops.txt")
           let tripsFileURL = directoryURL.appendingPathComponent("trips.txt")
           let stopTimesFileURL = directoryURL.appendingPathComponent("stop_times.txt")
           let calendarDatesFileURL = directoryURL.appendingPathComponent("calendar_dates.txt")
           
           // Lire et initialiser les différentes sections du feed
           self.agencies = try Agencies(from: agencyFileURL)
           self.routes = try Routes(from: routesFileURL)
           self.stops = try Stops(from: stopsFileURL)
           self.trips = try Trips(from: tripsFileURL)
           self.stopTimes = try StopTimes(from: stopTimesFileURL, timeZone: self.agencies?.first?.timeZone ?? TimeZone(secondsFromGMT: 0)!)
           self.calendarDates = try CalendarDates(from: calendarDatesFileURL)
       }
   }

   extension URLSession {
       /// Télécharge un fichier de manière synchrone (bloque le thread courant)
       func downloadTaskSync(with url: URL) throws -> (URL, URLResponse?) {
           let semaphore = DispatchSemaphore(value: 0)
           var tempFileURL: URL?
           var response: URLResponse?
           var downloadError: Error?

           let task = self.downloadTask(with: url) { url, urlResponse, error in
               tempFileURL = url
               response = urlResponse
               downloadError = error
               semaphore.signal()
           }
           task.resume()
           
           _ = semaphore.wait(timeout: .distantFuture)
           
           if let error = downloadError {
               throw error
           }
           
           guard let fileURL = tempFileURL else {
               throw LSError.downloadFailed
           }
           
           return (fileURL, response)
       }
   }

//public static func loadFromZipURL(_ zipURLString: String, completion: @escaping (Result<Feed, Error>) -> Void) {
//    // Impression pour le début de l'opération
//    print("Début du téléchargement à partir de l'URL : \(zipURLString)")
//
//    guard let zipURL = URL(string: zipURLString) else {
//        print("Erreur : URL invalide")
//        completion(.failure(LSError.invalidURL))
//        return
//    }
//
//    let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
//
//    // Impression pour la création du répertoire temporaire
//    print("Répertoire temporaire créé : \(tempDirectoryURL.path)")
//
//    // Téléchargement du fichier ZIP avec URLSession et completionHandler
//    let session = URLSession.shared
//    let request = URLRequest(url: zipURL)
//
//    let task = session.downloadTask(with: request) { (location, response, error) in
//        // Gestion des erreurs de téléchargement
//        if let error = error {
//            print("Erreur lors du téléchargement : \(error.localizedDescription)")
//            completion(.failure(error))
//            return
//        }
//
//        guard let location = location else {
//            print("Erreur : le fichier temporaire de téléchargement est introuvable.")
//            completion(.failure(LSError.downloadFailed))
//            return
//        }
//
//        // Impression de l'emplacement temporaire du fichier
//        print("Fichier téléchargé temporairement à : \(location.path)")
//
//        do {
//            let fileManager = FileManager.default
//            // Crée un répertoire temporaire pour extraire le ZIP
//            try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
//            print("Répertoire temporaire pour l'extraction créé : \(tempDirectoryURL.path)")
//
//            let tempFileURL = tempDirectoryURL.appendingPathComponent("export_gtfs_voyages.zip")
//
//            // Déplace le fichier temporaire téléchargé dans le répertoire contrôlé
//            print("Tentative de déplacement du fichier temporaire à : \(tempFileURL.path)")
//            try fileManager.moveItem(at: location, to: tempFileURL)
//            print("Fichier déplacé avec succès à : \(tempFileURL.path)")
//
//            // Utilise unzipItem pour extraire l'archive ZIP
//            print("Tentative d'extraction de l'archive ZIP à : \(tempDirectoryURL.path)")
//            try fileManager.unzipItem(at: tempFileURL, to: tempDirectoryURL)
//            print("Extraction réussie dans le répertoire : \(tempDirectoryURL.path)")
//
//            // Initialisation du Feed avec les fichiers extraits
//            let feed = try Feed(contentsOfURL: tempDirectoryURL)
//            print("Feed initialisé avec succès")
//            completion(.success(feed))
//
//        } catch {
//            print("Erreur lors de l'extraction de l'archive ZIP ou de l'initialisation du feed : \(error.localizedDescription)")
//            completion(.failure(LSError.extractionFailed))
//        }
//    }
//
//    // Lance la tâche de téléchargement
//    print("Lancement de la tâche de téléchargement")
//    task.resume()
//}
//
