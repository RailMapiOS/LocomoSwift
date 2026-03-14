//
//  ThreadSafeFileManager.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 04/10/2024.
//

import Foundation

class ThreadSafeFileManager: @unchecked Sendable {
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "threadsafe.fileManager.queue")

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try queue.sync {
            print("Moving file from \(srcURL.path) to \(dstURL.path)")
            try fileManager.moveItem(at: srcURL, to: dstURL)
        }
    }

    func unzipItem(at srcURL: URL, to dstURL: URL) throws {
        try queue.sync {
            print("Extracting \(srcURL.path) to \(dstURL.path)")
            try fileManager.unzipItem(at: srcURL, to: dstURL)
        }
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try queue.sync {
            print("Creating directory at \(url.path)")
            try fileManager.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
        }
    }

    // Remove directories or files
    func removeItem(at filePath: URL) throws {
        try queue.sync {
            do {
                print("Removing \(filePath.path)")
                try fileManager.removeItem(at: filePath)
            } catch {
                print("Error removing \(filePath.path): \(error)")
                throw error
            }
        }
    }

    var temporaryDirectory: URL {
        return fileManager.temporaryDirectory
    }
}
