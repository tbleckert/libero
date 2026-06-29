//
//  APIClient.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

protocol HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionHTTPTransport: HTTPTransport {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

struct APIClient {
    private let configuration: AppConfiguration
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let transport: any HTTPTransport

    init(configuration: AppConfiguration, transport: any HTTPTransport = URLSessionHTTPTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    func signIn(email: String, password: String, deviceName: String) async throws -> AuthSession {
        let response: AuthTokenResponse = try await send(
            path: "/api/v1/auth/tokens",
            method: "POST",
            body: AuthTokenRequest(
                email: email,
                password: password,
                deviceName: deviceName
            )
        )

        return AuthSession(token: response.data.token, user: response.data.user)
    }

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        deviceName: String
    ) async throws -> AuthSession {
        let response: AuthTokenResponse = try await send(
            path: "/api/v1/auth/register",
            method: "POST",
            body: RegisterUserRequest(
                name: name,
                email: email,
                password: password,
                passwordConfirmation: passwordConfirmation,
                deviceName: deviceName
            )
        )

        return AuthSession(token: response.data.token, user: response.data.user)
    }

    func forgotPassword(email: String) async throws {
        try await sendNoContent(
            path: "/api/v1/auth/forgot-password",
            method: "POST",
            body: ForgotPasswordRequest(email: email)
        )
    }

    func resendEmailVerification(token: String) async throws {
        try await sendNoContent(
            path: "/api/v1/auth/email/verification-notification",
            method: "POST",
            token: token,
            body: EmptyRequestBody()
        )
    }

    func currentUser(token: String) async throws -> AuthenticatedUser {
        let response: UserResponse = try await send(
            path: "/api/v1/user",
            method: "GET",
            token: token
        )

        return response.data
    }

    func signOut(token: String) async throws {
        try await sendNoContent(
            path: "/api/v1/auth/tokens/current",
            method: "DELETE",
            token: token
        )
    }

    private func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        token: String? = nil,
        body: Body
    ) async throws -> Response {
        var request = makeRequest(path: path, method: method)
        authenticate(&request, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        return try await send(request)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        token: String? = nil
    ) async throws -> Response {
        var request = makeRequest(path: path, method: method)
        authenticate(&request, token: token)

        return try await send(request)
    }

    private func sendNoContent<Body: Encodable>(
        path: String,
        method: String,
        token: String? = nil,
        body: Body
    ) async throws {
        var request = makeRequest(path: path, method: method)
        authenticate(&request, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        try await sendNoContent(request)
    }

    private func sendNoContent(
        path: String,
        method: String,
        token: String? = nil
    ) async throws {
        var request = makeRequest(path: path, method: method)
        authenticate(&request, token: token)

        try await sendNoContent(request)
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await transport.data(for: request)
        try validate(response: response, data: data)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIClientError.invalidResponse
        }
    }

    private func sendNoContent(_ request: URLRequest) async throws {
        let (data, response) = try await transport.data(for: request)
        try validate(response: response, data: data)
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: configuration.url(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        return request
    }

    private func authenticate(_ request: inout URLRequest, token: String?) {
        guard let token else {
            return
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let response = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200..<300).contains(response.statusCode) else {
            throw decodedError(from: data) ?? APIClientError.httpStatus(response.statusCode)
        }
    }

    private func decodedError(from data: Data) -> APIClientError? {
        guard !data.isEmpty else {
            return nil
        }

        if let validationError = try? decoder.decode(ValidationErrorResponse.self, from: data) {
            let firstFieldMessage = validationError.errors?
                .sorted { $0.key < $1.key }
                .compactMap { $0.value.first }
                .first

            return .message(firstFieldMessage ?? validationError.message)
        }

        if let messageError = try? decoder.decode(MessageErrorResponse.self, from: data) {
            return .message(messageError.message)
        }

        return nil
    }
}

enum APIClientError: LocalizedError, Equatable {
    case httpStatus(Int)
    case invalidResponse
    case message(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .httpStatus(let statusCode):
            return L10n.format("api.http_error", fallback: "The server returned status %d.", statusCode)
        case .invalidResponse:
            return L10n.string("api.invalid_response", fallback: "The server returned an unexpected response.")
        case .message(let message):
            return message
        }
    }
}

enum CurrentDevice {
    static var name: String {
        #if canImport(UIKit)
        UIDevice.current.name
        #else
        Host.current().localizedName ?? "Libero"
        #endif
    }
}

private struct AuthTokenRequest: Encodable {
    let email: String
    let password: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case deviceName = "device_name"
    }
}

private struct RegisterUserRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let passwordConfirmation: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case name
        case email
        case password
        case passwordConfirmation = "password_confirmation"
        case deviceName = "device_name"
    }
}

private struct ForgotPasswordRequest: Encodable {
    let email: String
}

private struct EmptyRequestBody: Encodable {}

private struct AuthTokenResponse: Decodable {
    let data: AuthTokenPayload
}

private struct AuthTokenPayload: Decodable {
    let token: String
    let user: AuthenticatedUser
}

private struct UserResponse: Decodable {
    let data: AuthenticatedUser
}

private struct ValidationErrorResponse: Decodable {
    let message: String
    let errors: [String: [String]]?
}

private struct MessageErrorResponse: Decodable {
    let message: String
}
