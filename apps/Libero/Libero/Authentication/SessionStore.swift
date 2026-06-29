//
//  SessionStore.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import Foundation
import Security

protocol SessionStoring: AnyObject {
    func loadSession() throws -> AuthSession?
    func saveSession(_ session: AuthSession) throws
    func clearSession() throws
}

final class KeychainSessionStore: SessionStoring {
    private let account: String
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let service: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "Libero",
        account: String = "current-session"
    ) {
        self.service = service
        self.account = account
    }

    func loadSession() throws -> AuthSession? {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw SessionStoreError.keychainStatus(status)
        }

        guard let data = item as? Data else {
            throw SessionStoreError.invalidData
        }

        return try decoder.decode(AuthSession.self, from: data)
    }

    func saveSession(_ session: AuthSession) throws {
        let data = try encoder.encode(session)
        var query = baseQuery()
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try updateSessionData(data)
            return
        }

        guard status == errSecSuccess else {
            throw SessionStoreError.keychainStatus(status)
        }
    }

    func clearSession() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        if status == errSecItemNotFound {
            return
        }

        guard status == errSecSuccess else {
            throw SessionStoreError.keychainStatus(status)
        }
    }

    private func updateSessionData(_ data: Data) throws {
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw SessionStoreError.keychainStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
        ]
    }
}

final class InMemorySessionStore: SessionStoring {
    private var session: AuthSession?

    init(session: AuthSession? = nil) {
        self.session = session
    }

    func loadSession() throws -> AuthSession? {
        session
    }

    func saveSession(_ session: AuthSession) throws {
        self.session = session
    }

    func clearSession() throws {
        session = nil
    }
}

enum SessionStoreError: LocalizedError {
    case invalidData
    case keychainStatus(OSStatus)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidData:
            return L10n.string("session.unreadable", fallback: "The saved session could not be read.")
        case .keychainStatus(let status):
            return L10n.format("session.keychain_failure", fallback: "Keychain returned status %d.", status)
        }
    }
}
