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
    
    /// Initializes an instance by loading GTFS data from a given URL, with optional ZIP file handling and temporary file cleanup.
    ///
    /// - Parameters:
    ///   - url: The URL pointing to the GTFS data source. If the URL points to a ZIP file, the file will be downloaded, extracted,
    ///          and the contents processed accordingly. Both local and remote URLs are supported.
    ///   - keepFiles: A Boolean flag indicating whether the temporary files and extracted contents should be retained
    ///                after processing. Defaults to `false`, which will remove temporary files upon completion.
    ///
    /// - Throws: An error if there are any issues with downloading, extracting, or loading the GTFS data files.
    ///
    /// This initializer performs the following steps:
    /// 1. **ZIP File Detection and Extraction**:
    ///     - If `url` has a `.zip` extension, it is treated as a ZIP file. A unique temporary directory is created
    ///       to hold the downloaded ZIP file and its extracted contents.
    ///     - If `url` is a local file URL, the ZIP file is directly extracted into the temporary directory.
    ///     - If `url` is a remote URL, the ZIP file is downloaded and then extracted into the temporary directory.
    /// 2. **File Loading**:
    ///     - After extraction, the initializer attempts to load GTFS-specific files (`agency.txt`, `routes.txt`, `stops.txt`,
    ///       `trips.txt`, `stop_times.txt`, and `calendar_dates.txt`) from the extracted contents.
    ///     - These files are used to populate the relevant GTFS data structures.
    /// 3. **Temporary File Cleanup**:
    ///     - If `keepFiles` is set to `false`, the initializer deletes the temporary directory, including both the downloaded
    ///       ZIP file and the extracted contents, after processing. This behavior ensures that the file system remains clean
    ///       by removing unnecessary files.
    ///
    /// ### Example Usage
    /// ```swift
    /// do {
    ///     let gtfsData = try GTFSData(contentsOfURL: url, keepFiles: false)
    ///     // Access GTFS data from gtfsData object
    /// } catch {
    ///     print("Failed to initialize GTFSData: \(error)")
    /// }
    /// ```
    ///
    /// This initializer provides a streamlined approach for handling GTFS data sources, supporting both local and remote
    /// ZIP file URLs, with an efficient cleanup process to manage temporary files.
    public init(contentsOfURL url: URL, keepFiles: Bool = false) async throws {
        let threadSafeFileManager = ThreadSafeFileManager()
        var directoryURL: URL = url
        var extractionDirectoryURL: URL? = nil  // Pour la suppression des fichiers temporaires après utilisation
        
        if url.pathExtension == "zip" {
            print("ZIP file detected, attempting download and extraction.")
            
            // Créer un dossier temporaire unique pour stocker le ZIP et les fichiers extraits
            let tempDirectoryURL = threadSafeFileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try await threadSafeFileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
            extractionDirectoryURL = tempDirectoryURL  // Affectation pour le nettoyage après l’utilisation
            
            // Générer un nom de fichier dynamique basé sur l'URL d'origine
            let tempFileName = url.lastPathComponent.isEmpty ? "downloadedFile.zip" : url.lastPathComponent
            let tempFileURL = tempDirectoryURL.appendingPathComponent(tempFileName)
            
            if url.isFileURL {
                // Extraction directe du fichier ZIP local
                try await threadSafeFileManager.unzipItem(at: url, to: tempDirectoryURL)
                print("Extraction successful at: \(tempDirectoryURL.path)")
                directoryURL = tempDirectoryURL
            } else {
                // Téléchargement du fichier ZIP distant et extraction
                directoryURL = try await withCheckedThrowingContinuation { continuation in
                    URLSession.shared.downloadTaskAsyncCompat(with: url) { result in
                        switch result {
                        case .success(let (downloadedFileURL, response)):
                            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                                do {
                                    try threadSafeFileManager.moveItem(at: downloadedFileURL, to: tempFileURL)
                                    try threadSafeFileManager.unzipItem(at: tempFileURL, to: tempDirectoryURL)
                                    print("Extraction successful at: \(tempDirectoryURL.path)")
                                    continuation.resume(returning: tempDirectoryURL)  // Retourne l'URL extraite
                                } catch {
                                    print("Error during file move or extraction: \(error)")
                                    continuation.resume(throwing: error)
                                }
                            } else {
                                continuation.resume(throwing: LSError.downloadFailed)
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
        
        let agencyFileURL = directoryURL.appendingPathComponent("agency.txt")
        let routesFileURL = directoryURL.appendingPathComponent("routes.txt")
        let stopsFileURL = directoryURL.appendingPathComponent("stops.txt")
        let tripsFileURL = directoryURL.appendingPathComponent("trips.txt")
        let stopTimesFileURL = directoryURL.appendingPathComponent("stop_times.txt")
        let calendarDatesFileURL = directoryURL.appendingPathComponent("calendar_dates.txt")
        
        self.agencies = try Agencies(from: agencyFileURL)
        self.routes = try Routes(from: routesFileURL)
        self.stops = try Stops(from: stopsFileURL)
        self.trips = try Trips(from: tripsFileURL)
        self.stopTimes = try StopTimes(from: stopTimesFileURL, timeZone: self.agencies?.first?.timeZone ?? TimeZone(secondsFromGMT: 0)!)
        self.calendarDates = try CalendarDates(from: calendarDatesFileURL)
        
        if !keepFiles {
            defer {
                do {
                    if let extractionDirectoryURL = extractionDirectoryURL {
                        try threadSafeFileManager.removeItem(at: extractionDirectoryURL)
                        print("Temporary extraction folder removed: \(extractionDirectoryURL.path)")
                    }
                } catch {
                    print("Error removing temporary extraction folder: \(error)")
                }
            }
        }
    }
    
    public init(agencices: Agencies? = nil, routes: Routes? = nil, stops: Stops? = nil, trips: Trips? = nil, stopTimes: StopTimes? = nil, calendarDates: CalendarDates? = nil) throws {
        self.agencies = agencices
        self.routes = routes
        self.stops = stops
        self.trips = trips
        self.stopTimes = stopTimes
        self.calendarDates = calendarDates
    }
}


extension URLSession {
    /// Downloads a file asynchronously, leveraging advanced `URLSession` background configurations on supported platforms for enhanced performance.
    func downloadTaskAsyncCompat(with url: URL, completion: @Sendable @escaping (Result<(URL, URLResponse?), LSError>) -> Void) {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            Task {
                do {
                    let (downloadedFileURL, response) = try await self.download(from: url)
                    completion(.success((downloadedFileURL, response)))
                } catch {
                    completion(.failure(.downloadFailed))
                }
            }
        } else if #available(iOS 13, macOS 10.15, *) {
            // Use background configuration with completion handlers for versions prior to async/await support
            let configuration = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
            let session = URLSession(configuration: configuration)
            let task = session.downloadTask(with: url) { downloadedFileURL, response, error in
                if let error = error {
                    print("Download error: \(error)")
                    completion(.failure(.downloadFailed))
                } else if let downloadedFileURL = downloadedFileURL {
                    completion(.success((downloadedFileURL, response)))
                } else {
                    completion(.failure(.downloadFailed))
                }
            }
            task.resume()
        } else {
            // Fallback for earlier versions
            let task = self.downloadTask(with: url) { downloadedFileURL, response, error in
                if let error = error {
                    print("Download error: \(error)")
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
}
