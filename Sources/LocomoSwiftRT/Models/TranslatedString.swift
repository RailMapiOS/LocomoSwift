//
//  TranslatedString.swift
//  LocomoSwift
//
//  An internationalized text payload with one or more language-tagged variants.
//

import Foundation

public struct TranslatedString: Hashable, Sendable {

    public struct Translation: Hashable, Sendable {
        public let text: String
        /// BCP-47 language code. `nil` when the producer didn't tag the string.
        public let language: String?

        public init(text: String, language: String? = nil) {
            self.text = text
            self.language = language
        }
    }

    public let translations: [Translation]

    public init(translations: [Translation]) {
        self.translations = translations
    }

    /// All texts available, in the order they were emitted by the producer.
    public var allTexts: [String] { translations.map(\.text) }

    /// Returns the best matching text for the given locale, following the
    /// resolution rules from the GTFS Realtime spec:
    ///
    /// 1. First exact language match.
    /// 2. First match on the **language code only** (`fr` matches `fr-CA`).
    /// 3. First translation tagged with no language.
    /// 4. First translation, regardless of language.
    public func text(for locale: Locale = .current) -> String? {
        guard !translations.isEmpty else { return nil }
        let target = locale.identifier.lowercased()
        let targetPrimary = locale.languageCode?.lowercased()

        if let exact = translations.first(where: { $0.language?.lowercased() == target }) {
            return exact.text
        }
        if let primary = targetPrimary,
           let match = translations.first(where: { ($0.language?.split(separator: "-").first.map(String.init))?.lowercased() == primary }) {
            return match.text
        }
        if let untagged = translations.first(where: { $0.language == nil || $0.language?.isEmpty == true }) {
            return untagged.text
        }
        return translations.first?.text
    }
}
