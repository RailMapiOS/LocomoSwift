//
//  TranslatedStringMapper.swift
//  LocomoSwift
//

import Foundation

enum TranslatedStringMapper {

    static func map(_ proto: TransitRealtime_TranslatedString) -> TranslatedString? {
        guard !proto.translation.isEmpty else { return nil }
        let translations = proto.translation.map {
            TranslatedString.Translation(
                text: $0.text,
                language: $0.hasLanguage && !$0.language.isEmpty ? $0.language : nil
            )
        }
        return TranslatedString(translations: translations)
    }

    static func mapImage(_ proto: TransitRealtime_TranslatedImage) -> TranslatedImage? {
        guard !proto.localizedImage.isEmpty else { return nil }
        let images = proto.localizedImage.compactMap { localized -> TranslatedImage.LocalizedImage? in
            guard let url = URL(string: localized.url) else { return nil }
            return TranslatedImage.LocalizedImage(
                url: url,
                mediaType: localized.mediaType,
                language: localized.hasLanguage && !localized.language.isEmpty ? localized.language : nil
            )
        }
        guard !images.isEmpty else { return nil }
        return TranslatedImage(images: images)
    }
}
