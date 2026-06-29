//
//  RegisterView.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI

struct RegisterView: View {
    @Environment(AuthenticationStore.self) private var authentication
    @FocusState private var focusedField: Field?
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var showPassword = false

    private var canCreateAccount: Bool {
        !trimmed(name).isEmpty
            && !trimmed(email).isEmpty
            && !password.isEmpty
            && !passwordConfirmation.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHeader(subtitle: "Create your account.")
                    .padding(.bottom, 48)

                VStack(spacing: 18) {
                    if let errorMessage = authentication.errorMessage {
                        AuthMessageView(message: errorMessage)
                    }

                    LabeledAuthField("Name") {
                        AuthInputContainer {
                            ZStack(alignment: .leading) {
                                if name.isEmpty {
                                    AuthPlaceholderText("Your name")
                                }

                                TextField("", text: $name)
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .accessibilityIdentifier("register.nameField")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .accessibilityIdentifier("register.emailField")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    LabeledAuthField("Password") {
                        AuthInputContainer {
                            ZStack(alignment: .leading) {
                                if password.isEmpty {
                                    AuthPlaceholderText("At least 8 characters")
                                }

                                Group {
                                    if showPassword {
                                        TextField("", text: $password)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("", text: $password)
                                            .textContentType(.newPassword)
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .accessibilityIdentifier("register.passwordField")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: togglePasswordVisibility) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showPassword ? Text("Hide password") : Text("Show password"))
                        }
                    }

                    LabeledAuthField("Confirm password") {
                        AuthInputContainer {
                            ZStack(alignment: .leading) {
                                if passwordConfirmation.isEmpty {
                                    AuthPlaceholderText("Repeat your password")
                                }

                                SecureField("", text: $passwordConfirmation)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .passwordConfirmation)
                                    .submitLabel(.go)
                                    .accessibilityIdentifier("register.passwordConfirmationField")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button(action: submit) {
                        AuthButtonLabel(
                            title: "Create account",
                            isLoading: authentication.isSigningIn,
                            isProminent: true
                        )
                    }
                    .accessibilityIdentifier("register.createAccountButton")
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .controlSize(.large)
                    .disabled(!canCreateAccount)
                    .allowsHitTesting(!authentication.isSigningIn)
                }
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 36)
            .padding(.top, 72)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onSubmit(handleSubmit)
    }

    private func handleSubmit() {
        switch focusedField {
        case .name:
            focusedField = .email
        case .email:
            focusedField = .password
        case .password:
            focusedField = .passwordConfirmation
        case .passwordConfirmation, nil:
            submit()
        }
    }

    private func submit() {
        guard canCreateAccount, !authentication.isSigningIn else {
            return
        }

        focusedField = nil

        Task {
            await authentication.register(
                name: name,
                email: email,
                password: password,
                passwordConfirmation: passwordConfirmation
            )

            if authentication.session != nil {
                password = ""
                passwordConfirmation = ""
            }
        }
    }

    private func togglePasswordVisibility() {
        showPassword.toggle()
        focusedField = .password
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum Field {
        case name
        case email
        case password
        case passwordConfirmation
    }
}

#Preview("Default") {
    NavigationStack {
        RegisterView()
            .environment(AuthenticationStore.preview())
    }
}
