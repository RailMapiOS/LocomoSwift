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

/// A struct representing a feed of transit data.
///
/// A `Feed` contains various types of data related to agencies, routes, stops, trips, and more.
/// - Tag: Feed
public struct Feed: Identifiable {
    /// A unique identifier for the feed.
    public let id = UUID()
    /// Agencies associated with the feed.
    public var agencies: Agencies?
    /// Routes associated with the feed.
    public var routes: Routes?
    /// Stops associated with the feed.
    public var stops: Stops?
    /// Trips associated with the feed.
    public var trips: Trips?
    /// Stop times associated with the feed.
    public var stopTimes: StopTimes?
    /// Calendar dates associated with the feed.
    public var calendarDates: CalendarDates?

    /// The first agency found in the feed, if any.
    public var agency: Agency? {
        return agencies?.first
    }
    
    /// Initializes a `Feed` by loading data from the specified URL.
    ///
    /// If the URL points to a ZIP file, it is downloaded and extracted before loading the data.
    /// - Parameter url: The URL to load the feed from.
    /// - Throws: An error if the download or extraction fails, or if the feed cannot be initialized.
    public init(contentsOfURL url: URL) throws {
        let threadSafeFileManager = ThreadSafeFileManager()
        var directoryURL: URL = url
        
        if url.pathExtension == "zip" {
            print("ZIP file detected, attempting download and extraction.")
            
            let tempDirectoryURL = threadSafeFileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try threadSafeFileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
            let tempFileURL = tempDirectoryURL.appendingPathComponent("export_gtfs_voyages.zip")
            
            let group = DispatchGroup()
            group.enter()
            
            if url.isFileURL {
                // Extraction directe du fichier ZIP local
                try threadSafeFileManager.unzipItem(at: url, to: tempDirectoryURL)
                print("Extraction successful at: \(tempDirectoryURL.path)")
                directoryURL = tempDirectoryURL
                group.leave()
            } else {
                // Téléchargement du fichier ZIP distant
                URLSession.shared.downloadTaskAsyncCompat(with: url) { result in
                    defer { group.leave() }
                    switch result {
                    case .success(let (downloadedFileURL, response)):
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                            do {
                                try threadSafeFileManager.moveItem(at: downloadedFileURL, to: tempFileURL)
                                try threadSafeFileManager.unzipItem(at: tempFileURL, to: tempDirectoryURL)
                                print("Extraction successful at: \(tempDirectoryURL.path)")
                            } catch {
                                print("Error during file move or extraction: \(error)")
                            }
                        } else {
                            print("Download failed with invalid response: \(String(describing: response))")
                        }
                    case .failure(let error):
                        print("Download error: \(error.localizedDescription)")
                    }
                }
            }

            // Attendre que le téléchargement et l'extraction soient terminés avant de continuer
            group.wait()

            // Une fois l'extraction terminée, on continue avec le chargement des fichiers GTFS
            directoryURL = tempDirectoryURL
        }
        
        let agencyFileURL = directoryURL.appendingPathComponent("agency.txt")
        let routesFileURL = directoryURL.appendingPathComponent("routes.txt")
        let stopsFileURL = directoryURL.appendingPathComponent("stops.txt")
        let tripsFileURL = directoryURL.appendingPathComponent("trips.txt")
        let stopTimesFileURL = directoryURL.appendingPathComponent("stop_times.txt")
        let calendarDatesFileURL = directoryURL.appendingPathComponent("calendar_dates.txt")
        
        // Charger les sections du flux
        self.agencies = try Agencies(from: agencyFileURL)
        self.routes = try Routes(from: routesFileURL)
        self.stops = try Stops(from: stopsFileURL)
        self.trips = try Trips(from: tripsFileURL)
        self.stopTimes = try StopTimes(from: stopTimesFileURL, timeZone: self.agencies?.first?.timeZone ?? TimeZone(secondsFromGMT: 0)!)
        self.calendarDates = try CalendarDates(from: calendarDatesFileURL)
    }
}


extension URLSession {
    /// Télécharge un fichier de manière asynchrone en utilisant completion handlers pour compatibilité iOS/iPadOS/macOS
    func downloadTaskAsyncCompat(with url: URL, completion: @Sendable @escaping (Result<(URL, URLResponse?), LSError>) -> Void) {
        let task = self.downloadTask(with: url) { downloadedFileURL, response, error in
            if let error = error as NSError?, error.domain == NSURLErrorDomain {
                completion(.failure(.downloadFailed))
            } else if let downloadedFileURL = downloadedFileURL {
                completion(.success((downloadedFileURL, response)))
            } else {
                completion(.failure(.downloadFailed))
            }
        }
        task.resume()
    }
}

