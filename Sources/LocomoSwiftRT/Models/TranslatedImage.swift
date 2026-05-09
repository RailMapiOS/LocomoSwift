//
//  TranslatedImage.swift
//  LocomoSwift
//
//  An internationalized image payload — one URL per language.
//

import Foundation

public struct TranslatedImage: Hashable, Sendable {

    public struct LocalizedImage: Hashable, Sendable {
        public let url: URL
        /// IANA media type, e.g. `image/png`. Always starts with `image/`.
        public let mediaType: String
        /// BCP-47 language code, `nil` if untagged.
        public let language: String?

        public init(url: URL, mediaType: String, language: String? = nil) {
            self.url = url
            self.mediaType = mediaType
            self.language = language
        }
    }

    public let images: [LocalizedImage]

    public init(images: [LocalizedImage]) {
        self.images = images
    }

    /// Best matching image URL for the given locale, using the same
    /// resolution rules as ``TranslatedString``.
    public func image(for locale: Locale = .current) -> LocalizedImage? {
        guard !images.isEmpty else { return nil }
        let target = locale.identifier.lowercased()
        let targetPrimary = locale.languageCode?.lowercased()

        if let exact = images.first(where: { $0.language?.lowercased() == target }) {
            return exact
        }
        if let primary = targetPrimary,
           let match = images.first(where: { ($0.language?.split(separator: "-").first.map(String.init))?.lowercased() == primary }) {
            return match
        }
        if let untagged = images.first(where: { $0.language == nil || $0.language?.isEmpty == true }) {
            return untagged
        }
        return images.first
    }
}
