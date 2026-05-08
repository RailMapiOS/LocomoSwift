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
            return "The URL is invalid."
        case .downloadFailed:
            return "File download failed."
        case .fileNotFound:
            return "Temporary file not found."
        case .extractionFailed:
            return "ZIP archive extraction failed."
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
    /// Shapes associated with the feed (optional in GTFS).
    public var shapes: Shapes?

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
    ///     - If `url` has a `.zip` extension, it is treated as a ZIP file.
    ///     - ZIP entries are extracted selectively (only GTFS files needed) to minimize I/O.
    /// 2. **Concurrent Parsing**:
    ///     - `agency.txt` is parsed first (required for timezone).
    ///     - All other files are parsed concurrently using `async let`.
    /// 3. **Temporary File Cleanup**:
    ///     - If `keepFiles` is set to `false`, the initializer deletes temporary files after processing.
    ///
    /// ### Example Usage
    /// ```swift
    /// do {
    ///     let gtfsData = try await Feed(contentsOfURL: url, keepFiles: false)
    ///     // Access GTFS data from gtfsData object
    /// } catch {
    ///     print("Failed to initialize Feed: \(error)")
    /// }
    /// ```
    public init(contentsOfURL url: URL, keepFiles: Bool = false) async throws {
        if url.pathExtension == "zip" {
            try await self.init(contentsOfZIP: url, keepFiles: keepFiles)
        } else {
            // Local directory — parse files directly
            try self.init(contentsOfDirectory: url)
        }
    }

    /// Initialize from a local directory containing extracted GTFS text files.
    private init(contentsOfDirectory directoryURL: URL) throws {
        let agencyFileURL = directoryURL.appendingPathComponent("agency.txt")
        let routesFileURL = directoryURL.appendingPathComponent("routes.txt")
        let stopsFileURL = directoryURL.appendingPathComponent("stops.txt")
        let tripsFileURL = directoryURL.appendingPathComponent("trips.txt")
        let stopTimesFileURL = directoryURL.appendingPathComponent("stop_times.txt")
        let calendarDatesFileURL = directoryURL.appendingPathComponent("calendar_dates.txt")
        let shapesFileURL = directoryURL.appendingPathComponent("shapes.txt")

        // Phase A: Parse agencies first (needed for timezone)
        self.agencies = try Agencies(from: agencyFileURL)
        guard let agencyTimeZone = self.agencies?.first?.timeZone else {
            throw LSError.missingRequiredFields
        }

        // Phase B: Parse remaining files (sequential for directory, concurrent for ZIP)
        self.routes = try Routes(from: routesFileURL)
        self.stops = try Stops(from: stopsFileURL)
        self.trips = try Trips(from: tripsFileURL)
        self.stopTimes = try StopTimes(from: stopTimesFileURL, timeZone: agencyTimeZone)
        self.calendarDates = try CalendarDates(from: calendarDatesFileURL)

        // shapes.txt is optional in GTFS
        if FileManager.default.fileExists(atPath: shapesFileURL.path) {
            self.shapes = try Shapes(from: shapesFileURL)
        }
    }

    /// Initialize from a ZIP archive URL (local or remote) with selective extraction
    /// and concurrent CSV parsing.
    private init(contentsOfZIP url: URL, keepFiles: Bool) async throws {
        let threadSafeFileManager = ThreadSafeFileManager()
        let tempDirectoryURL = threadSafeFileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try threadSafeFileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)

        defer {
            if !keepFiles {
                do {
                    try threadSafeFileManager.removeItem(at: tempDirectoryURL)
                    print("Temporary extraction folder removed: \(tempDirectoryURL.path)")
                } catch {
                    print("Error removing temporary extraction folder: \(error)")
                }
            }
        }

        let archiveURL: URL

        if url.isFileURL {
            archiveURL = url
        } else {
            // Download remote ZIP
            let tempFileName = url.lastPathComponent.isEmpty ? "downloadedFile.zip" : url.lastPathComponent
            let tempFileURL = tempDirectoryURL.appendingPathComponent(tempFileName)

            let (downloadedFileURL, response) = try await URLSession.shared.download(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw LSError.downloadFailed
            }

            try threadSafeFileManager.moveItem(at: downloadedFileURL, to: tempFileURL)
            archiveURL = tempFileURL
            print("ZIP downloaded to: \(tempFileURL.path)")
        }

        // Selective extraction: read only the GTFS files we need
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw LSError.extractionFailed
        }

        let gtfsFileNames = ["agency.txt", "routes.txt", "stops.txt", "trips.txt", "stop_times.txt", "calendar_dates.txt", "shapes.txt"]
        var fileContents: [String: String] = [:]

        for fileName in gtfsFileNames {
            // Look for the entry at root or inside a subdirectory
            if let entry = archive[fileName] ?? Self.findEntry(named: fileName, in: archive) {
                var data = Data()
                _ = try archive.extract(entry) { chunk in
                    data.append(chunk)
                }
                fileContents[fileName] = String(data: data, encoding: .utf8)
            }
        }

        print("Extracted \(fileContents.count) GTFS files from ZIP")

        // Phase A: Parse agencies first (needed for timezone)
        guard let agencyContent = fileContents["agency.txt"] else {
            throw LSError.fileNotFound
        }
        self.agencies = try Agencies(from: agencyContent)

        guard let agencyTimeZone = self.agencies?.first?.timeZone else {
            throw LSError.missingRequiredFields
        }

        // Phase B: Parse remaining files concurrently
        let routesContent = fileContents["routes.txt"]
        let stopsContent = fileContents["stops.txt"]
        let tripsContent = fileContents["trips.txt"]
        let stopTimesContent = fileContents["stop_times.txt"]
        let calendarDatesContent = fileContents["calendar_dates.txt"]
        let shapesContent = fileContents["shapes.txt"]
        let tz = agencyTimeZone

        async let routesParsing: Routes? = {
            guard let content = routesContent else { return nil }
            return try Routes(from: content)
        }()

        async let stopsParsing: Stops? = {
            guard let content = stopsContent else { return nil }
            return try Stops(from: content)
        }()

        async let tripsParsing: Trips? = {
            guard let content = tripsContent else { return nil }
            return try Trips(from: content)
        }()

        async let stopTimesParsing: StopTimes? = {
            guard let content = stopTimesContent else { return nil }
            return try StopTimes(from: content, timeZone: tz)
        }()

        async let calendarDatesParsing: CalendarDates? = {
            guard let content = calendarDatesContent else { return nil }
            return try CalendarDates(from: content)
        }()

        async let shapesParsing: Shapes? = {
            guard let content = shapesContent else { return nil }
            return try Shapes(from: content)
        }()

        self.routes = try await routesParsing
        self.stops = try await stopsParsing
        self.trips = try await tripsParsing
        self.stopTimes = try await stopTimesParsing
        self.calendarDates = try await calendarDatesParsing
        self.shapes = try await shapesParsing
    }

    /// Find a ZIP entry by filename, searching inside subdirectories.
    private static func findEntry(named fileName: String, in archive: Archive) -> Entry? {
        for entry in archive {
            if entry.path.hasSuffix("/\(fileName)") || entry.path == fileName {
                return entry
            }
        }
        return nil
    }

    public init(agencices: Agencies? = nil, routes: Routes? = nil, stops: Stops? = nil, trips: Trips? = nil, stopTimes: StopTimes? = nil, calendarDates: CalendarDates? = nil, shapes: Shapes? = nil) throws {
        self.agencies = agencices
        self.routes = routes
        self.stops = stops
        self.trips = trips
        self.stopTimes = stopTimes
        self.calendarDates = calendarDates
        self.shapes = shapes
    }
}
