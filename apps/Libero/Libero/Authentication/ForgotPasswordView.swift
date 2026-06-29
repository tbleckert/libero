//
//  ForgotPasswordView.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthenticationStore.self) private var authentication
    @FocusState private var isEmailFocused: Bool
    @State private var email = ""
    @State private var errorMessage: String?
    @State private var isSending = false
    @State private var successMessage: String?

    private var canSend: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHeader(subtitle: "Reset your password.")
                    .padding(.bottom, 48)

                VStack(spacing: 18) {
                    if let successMessage {
                        AuthMessageView(message: successMessage)
                    }

                    if let errorMessage {
                        AuthMessageView(message: errorMessage)
                    }

                    LabeledAuthField("Email address") {
                        AuthInputContainer {
                            ZStack(alignment: .leading) {
                                if email.isEmpty {
                                    AuthPlaceholderText("you@example.com")
                                }

                                TextField("", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($isEmailFocused)
                                    .submitLabel(.go)
                                    .accessibilityIdentifier("forgotPassword.emailField")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button(action: sendResetLink) {
                        AuthButtonLabel(title: "Send reset link", isLoading: isSending, isProminent: true)
                    }
                    .accessibilityIdentifier("forgotPassword.sendButton")
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .controlSize(.large)
                    .disabled(!canSend)
                    .allowsHitTesting(!isSending)
                }
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 36)
            .padding(.top, 72)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onSubmit(sendResetLink)
    }

    private func sendResetLink() {
        guard canSend, !isSending else {
            return
        }

        isEmailFocused = false
        isSending = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                try await authentication.sendPasswordReset(email: email)
                successMessage = L10n.string(
                    "auth.password_reset.sent",
                    fallback: "If that email exists, a reset link is on its way."
                )
            } catch {
                errorMessage = error.localizedDescription
            }

            isSending = false
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environment(AuthenticationStore.preview())
    }
}
