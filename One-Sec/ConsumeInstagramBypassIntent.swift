//
//  ConsumeInstagramBypassIntent.swift
//  One-Sec
//
//  Created by Christina Go on 10/25/26.
//



import AppIntents

struct ConsumeInstagramBypassIntent: AppIntent {
    static var title: LocalizedStringResource =
        "Check Instagram Bypass"

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let defaults = UserDefaults.standard

        let timestamp = defaults.double(
            forKey: "instagramBypassTimestamp"
        )

        let shouldBypass =
            timestamp > 0 &&
            Date().timeIntervalSince1970 - timestamp < 5

        // Consume the bypass so it cannot be reused.
        defaults.set(0.0, forKey: "instagramBypassTimestamp")

        return .result(value: shouldBypass)
    }
}
