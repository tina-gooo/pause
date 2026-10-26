//
//  ConsumeAppBypassIntent.swift
//  One-Sec
//
//  Created by Christina Go on 10/25/26.
//



import AppIntents

struct ConsumeAppBypassIntent: AppIntent {
    static var title: LocalizedStringResource = "Check App Bypass"

    @Parameter(title: "App ID")
    var appID: String

    init() {}

    init(appID: String) {
        self.appID = appID
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let defaults = UserDefaults.standard
        let key = "\(appID)BypassTimestamp"

        let timestamp = defaults.double(forKey: key)

        let shouldBypass =
            timestamp > 0 &&
            Date().timeIntervalSince1970 - timestamp < 5

        // Consume the bypass so it cannot be reused.
        defaults.set(0.0, forKey: key)

        return .result(value: shouldBypass)
    }
}
