//
//  L10n.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import Foundation

enum L10n {
    nonisolated static func string(_ key: String, fallback: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: "")
    }

    nonisolated static func format(_ key: String, fallback: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key, fallback: fallback),
            locale: .current,
            arguments: arguments
        )
    }
}
