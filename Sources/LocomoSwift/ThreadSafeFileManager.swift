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
            try fileManager.moveItem(at: srcURL, to: dstURL)
        }
    }

    func unzipItem(at srcURL: URL, to dstURL: URL) throws {
        try queue.sync {
            try fileManager.unzipItem(at: srcURL, to: dstURL)
        }
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try queue.sync {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
        }
    }

    var temporaryDirectory: URL {
        return fileManager.temporaryDirectory
    }
}
