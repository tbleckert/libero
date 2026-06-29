//
//  AuthenticationStore.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthenticationStore {
    private let apiClient: APIClient
    private let deviceName: String
    private let sessionStore: SessionStoring

    var errorMessage: String?
    var isSigningIn = false
    var session: AuthSession?

    convenience init(apiClient: APIClient) {
        self.init(
            apiClient: apiClient,
            sessionStore: KeychainSessionStore(),
            deviceName: CurrentDevice.name
        )
    }

    init(
        apiClient: APIClient,
        sessionStore: SessionStoring,
        deviceName: String
    ) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.deviceName = deviceName
        session = try? sessionStore.loadSession()
    }

    func signIn(email: String, password: String) async {
        guard !isSigningIn else {
            return
        }

        isSigningIn = true
        errorMessage = nil
        defer {
            isSigningIn = false
        }

        do {
            let session = try await apiClient.signIn(
                email: trimmed(email),
                password: password,
                deviceName: deviceName
            )
            try sessionStore.saveSession(session)
            self.session = session
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String
    ) async {
        guard !isSigningIn else {
            return
        }

        isSigningIn = true
        errorMessage = nil
        defer {
            isSigningIn = false
        }

        do {
            let session = try await apiClient.register(
                name: trimmed(name),
                email: trimmed(email),
                password: password,
                passwordConfirmation: passwordConfirmation,
                deviceName: deviceName
            )
            try sessionStore.saveSession(session)
            self.session = session
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await apiClient.forgotPassword(email: trimmed(email))
    }

    func resendEmailVerification(for session: AuthSession) async throws {
        try await apiClient.resendEmailVerification(token: session.token)
    }

    @discardableResult
    func currentUser(for session: AuthSession) async throws -> AuthenticatedUser {
        let user = try await apiClient.currentUser(token: session.token)
        saveLocally(AuthSession(token: session.token, user: user))

        return user
    }

    func signOut() async {
        let token = session?.token
        session = nil
        errorMessage = nil
        try? sessionStore.clearSession()

        if let token {
            try? await apiClient.signOut(token: token)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func saveLocally(_ session: AuthSession) {
        try? sessionStore.saveSession(session)
        self.session = session
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension AuthenticationStore {
    static func preview(
        session: AuthSession? = nil,
        errorMessage: String? = nil
    ) -> AuthenticationStore {
        let store = AuthenticationStore(
            apiClient: APIClient(configuration: AppConfiguration(apiBaseURL: URL(string: "https://libero.test")!)),
            sessionStore: InMemorySessionStore(session: session),
            deviceName: "Preview iPhone"
        )

        store.errorMessage = errorMessage

        return store
    }
}
