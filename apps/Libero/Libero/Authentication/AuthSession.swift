//
//  AuthSession.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import Foundation

struct AuthSession: Codable, Equatable, Sendable {
    let token: String
    var user: AuthenticatedUser
}

struct AuthenticatedUser: Codable, Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let email: String
    let emailVerifiedAt: String?
    let needsEmailVerification: Bool
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case emailVerifiedAt = "email_verified_at"
        case needsEmailVerification = "needs_email_verification"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var shouldVerifyEmail: Bool {
        needsEmailVerification
    }
}

extension AuthSession {
    static let preview = AuthSession(
        token: "preview-token",
        user: .preview(needsEmailVerification: false)
    )
}

extension AuthenticatedUser {
    static func preview(needsEmailVerification: Bool = false) -> AuthenticatedUser {
        AuthenticatedUser(
            id: 1,
            name: "Tobias Bleckert",
            email: "tobias@libero.test",
            emailVerifiedAt: needsEmailVerification ? nil : "2026-06-29T12:00:00+00:00",
            needsEmailVerification: needsEmailVerification,
            createdAt: "2026-06-29T12:00:00+00:00",
            updatedAt: "2026-06-29T12:00:00+00:00"
        )
    }
}
