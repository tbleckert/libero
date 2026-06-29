//
//  EmailVerificationView.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI

struct EmailVerificationView: View {
    @Environment(AuthenticationStore.self) private var authentication
    let session: AuthSession

    @State private var errorMessage: String?
    @State private var isRefreshing = false
    @State private var isSending = false
    @State private var successMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHeader(subtitle: "Verify your email.")
                    .padding(.bottom, 40)

                VStack(spacing: 18) {
                    Text(instructionText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let successMessage {
                        AuthMessageView(message: successMessage)
                    }

                    if let currentErrorMessage {
                        AuthMessageView(message: currentErrorMessage)
                    }

                    Button(action: resendVerificationLink) {
                        AuthButtonLabel(
                            title: "Resend verification link",
                            isLoading: isSending,
                            isProminent: true
                        )
                    }
                    .accessibilityIdentifier("emailVerification.resendButton")
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .controlSize(.large)
                    .allowsHitTesting(!isSending)

                    Button(action: refreshUser) {
                        AuthButtonLabel(title: "I verified my email", isLoading: isRefreshing)
                    }
                    .accessibilityIdentifier("emailVerification.refreshButton")
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .controlSize(.large)
                    .allowsHitTesting(!isRefreshing)

                    Button("Sign out", action: signOut)
                        .font(.callout)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 36)
            .padding(.top, 108)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.screenBackground)
    }

    private var instructionText: String {
        L10n.format(
            "auth.email_verification.instructions",
            fallback: "We sent a verification link to %@. Open it, then return here to continue.",
            session.user.email
        )
    }

    private var currentErrorMessage: String? {
        errorMessage ?? authentication.errorMessage
    }

    private func resendVerificationLink() {
        guard !isSending else {
            return
        }

        isSending = true
        errorMessage = nil
        authentication.clearError()
        successMessage = nil

        Task {
            do {
                try await authentication.resendEmailVerification(for: session)
                successMessage = L10n.string(
                    "auth.email_verification.sent",
                    fallback: "A fresh verification link is on its way."
                )
            } catch {
                errorMessage = error.localizedDescription
            }

            isSending = false
        }
    }

    private func refreshUser() {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        errorMessage = nil
        authentication.clearError()
        successMessage = nil

        Task {
            do {
                let user = try await authentication.currentUser(for: session)

                if user.shouldVerifyEmail {
                    successMessage = L10n.string(
                        "auth.email_verification.not_verified_yet",
                        fallback: "We could not confirm the verification yet. Open the email link, then try again."
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isRefreshing = false
        }
    }

    private func signOut() {
        Task {
            await authentication.signOut()
        }
    }
}

#Preview {
    EmailVerificationView(
        session: AuthSession(
            token: "preview-token",
            user: .preview(needsEmailVerification: true)
        )
    )
    .environment(AuthenticationStore.preview())
}
