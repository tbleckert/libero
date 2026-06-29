//
//  LiberoTests.swift
//  LiberoTests
//
//  Created by Tobias Bleckert on 2026-06-29.
//

import Testing
import Foundation
@testable import Libero

@MainActor
struct LiberoTests {

    @Test func configurationBuildsAPIURLs() throws {
        let configuration = try AppConfiguration(apiBaseURLString: "https://libero.test")

        #expect(configuration.url(path: "/api/v1/user").absoluteString == "https://libero.test/api/v1/user")
        #expect(
            configuration.url(path: "/api/v1/search?q=left%20wing").absoluteString
                == "https://libero.test/api/v1/search?q=left%20wing"
        )
    }

    @Test func apiClientCreatesSessionFromSignInResponse() async throws {
        let transport = MockHTTPTransport(
            statusCode: 200,
            body: """
            {
              "data": {
                "token": "plain-text-token",
                "user": {
                  "id": 7,
                  "name": "Ada Lovelace",
                  "email": "ada@example.com",
                  "email_verified_at": null,
                  "needs_email_verification": true,
                  "created_at": "2026-06-29T12:00:00+00:00",
                  "updated_at": "2026-06-29T12:00:00+00:00"
                }
              }
            }
            """
        )
        let client = APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://libero.test")!),
            transport: transport
        )

        let session = try await client.signIn(
            email: "ada@example.com",
            password: "password",
            deviceName: "Ada iPhone"
        )

        let request = try #require(transport.requests.first)
        let body = try #require(request.httpBody)
        let payload = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: String]
        )

        #expect(request.url?.absoluteString == "https://libero.test/api/v1/auth/tokens")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(payload["device_name"] == "Ada iPhone")
        #expect(session.token == "plain-text-token")
        #expect(session.user.email == "ada@example.com")
        #expect(session.user.shouldVerifyEmail)
    }

    @Test func apiClientSurfacesLaravelValidationMessages() async throws {
        let transport = MockHTTPTransport(
            statusCode: 422,
            body: """
            {
              "message": "The email field is required.",
              "errors": {
                "email": ["The email field is required."]
              }
            }
            """
        )
        let client = APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://libero.test")!),
            transport: transport
        )

        do {
            try await client.forgotPassword(email: "")
            Issue.record("Expected forgotPassword to throw.")
        } catch {
            #expect(error.localizedDescription == "The email field is required.")
        }
    }

}

@MainActor
private final class MockHTTPTransport: HTTPTransport {
    private let body: String
    private let statusCode: Int

    private(set) var requests: [URLRequest] = []

    init(statusCode: Int, body: String) {
        self.statusCode = statusCode
        self.body = body
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)

        let response = HTTPURLResponse(
            url: try #require(request.url),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )

        return (Data(body.utf8), try #require(response))
    }
}
