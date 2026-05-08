//
//  Fixtures.swift
//  LocomoSwiftTests
//

import Foundation

enum Fixtures {
    static var miniGTFSFolderURL: URL {
        guard let url = Bundle.module.url(forResource: "MiniGTFS", withExtension: nil) else {
            fatalError("MiniGTFS folder fixture not found in test bundle")
        }
        return url
    }

    static var miniGTFSZipURL: URL {
        guard let url = Bundle.module.url(forResource: "MiniGTFS", withExtension: "zip") else {
            fatalError("MiniGTFS.zip fixture not found in test bundle")
        }
        return url
    }

    static var sncfZipURL: URL? {
        Bundle.module.url(forResource: "export_gtfs_voyages", withExtension: "zip")
    }

    /// Returns the contents of a Mini GTFS file by short name (e.g. "stops.txt").
    static func miniGTFSContent(_ filename: String) throws -> String {
        let url = miniGTFSFolderURL.appendingPathComponent(filename)
        return try String(contentsOf: url, encoding: .utf8)
    }

    static func makeTempCopyOfMiniGTFS() throws -> URL {
        let fm = FileManager.default
        let dst = fm.temporaryDirectory.appendingPathComponent("LocomoSwiftTests-\(UUID().uuidString)")
        try fm.createDirectory(at: dst, withIntermediateDirectories: true)
        for name in ["agency.txt", "routes.txt", "stops.txt", "trips.txt", "stop_times.txt", "calendar_dates.txt"] {
            let src = miniGTFSFolderURL.appendingPathComponent(name)
            try fm.copyItem(at: src, to: dst.appendingPathComponent(name))
        }
        return dst
    }
}
