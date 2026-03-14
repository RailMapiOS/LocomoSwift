//
//  Feed+DataSource.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 14/07/2025.
//

import Foundation

// MARK: - Feed initialization from DataSource

extension Feed {

    /// Initializes a Feed from a DataSource that provides a static GTFS feed.
    ///
    /// ```swift
    /// var feed = try await Feed(from: .sncf)
    /// ```
    ///
    /// - Throws: ``RealtimeError/staticFeedNotConfigured(_:)`` if the source has no `staticFeedURL`.
    public init(from source: DataSource, keepFiles: Bool = false) async throws {
        guard let url = source.staticFeedURL else {
            throw RealtimeError.staticFeedNotConfigured(source.identifier)
        }
        try await self.init(contentsOfURL: url, keepFiles: keepFiles)
    }
}
