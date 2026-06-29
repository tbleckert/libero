//
//  AppConfiguration.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import Foundation

struct AppConfiguration: Equatable, Sendable {
    nonisolated static let apiBaseURLKey = "LIBERO_API_BASE_URL"
    nonisolated static let defaultAPIBaseURL = "http://libero-2.test"

    let apiBaseURL: URL

    init(apiBaseURL: URL) {
        self.apiBaseURL = apiBaseURL
    }

    init(apiBaseURLString: String) throws {
        let value = apiBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            throw AppConfigurationError.missingAPIBaseURL
        }

        guard
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            throw AppConfigurationError.invalidAPIBaseURL(value)
        }

        self.apiBaseURL = url
    }

    static func current(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> AppConfiguration {
        let apiBaseURL = configurationValue(for: apiBaseURLKey, bundle: bundle, environment: environment)
            ?? defaultAPIBaseURL

        return try AppConfiguration(apiBaseURLString: apiBaseURL)
    }

    func url(path: String) -> URL {
        let parts = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let pathPart = parts.first.map(String.init) ?? ""
        let queryPart = parts.count > 1 ? String(parts[1]) : nil

        let url = pathPart
            .split(separator: "/")
            .map(String.init)
            .reduce(apiBaseURL) { url, pathComponent in
                url.appending(path: pathComponent)
            }

        guard let queryPart, !queryPart.isEmpty else {
            return url
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.percentEncodedQuery = queryPart

        return components?.url ?? url
    }

    private static func configurationValue(
        for key: String,
        bundle: Bundle,
        environment: [String: String]
    ) -> String? {
        [
            environment[key],
            bundle.object(forInfoDictionaryKey: key) as? String,
        ].compactMap { value -> String? in
            guard let value else {
                return nil
            }

            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

            return trimmedValue.isEmpty ? nil : trimmedValue
        }.first
    }
}

enum AppConfigurationError: LocalizedError, Equatable {
    case missingAPIBaseURL
    case invalidAPIBaseURL(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .missingAPIBaseURL:
            return L10n.format(
                "configuration.missing_api_base_url",
                fallback: "Set %@ before launching Libero.",
                AppConfiguration.apiBaseURLKey
            )
        case .invalidAPIBaseURL(let value):
            return L10n.format(
                "configuration.invalid_api_base_url",
                fallback: "%@ is not a valid API base URL.",
                value
            )
        }
    }
}
