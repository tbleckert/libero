//
//  LoginView.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthenticationStore.self) private var authentication
    @FocusState private var focusedField: Field?
    @State private var email = ""
    @State private var path: [AuthenticationRoute] = []
    @State private var password = ""
    @State private var showPassword = false

    private var hasCredentials: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    AuthHeader(subtitle: "Sign in to continue.")
                        .padding(.bottom, 48)

                    VStack(spacing: 18) {
                        if let errorMessage = authentication.errorMessage {
                            AuthMessageView(message: errorMessage)
                        }

                        LabeledAuthField("Email address") {
                            AuthInputContainer {
                                ZStack(alignment: .leading) {
                                    if email.isEmpty {
                                        AuthPlaceholderText("you@example.com")
                                    }

                                    TextField("", text: $email)
                                        .textContentType(.username)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .accessibilityIdentifier("login.emailField")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        LabeledAuthField("Password") {
                            AuthInputContainer {
                                ZStack(alignment: .leading) {
                                    if password.isEmpty {
                                        AuthPlaceholderText("Enter your password")
                                    }

                                    Group {
                                        if showPassword {
                                            TextField("", text: $password)
                                                .textContentType(.password)
                                        } else {
                                            SecureField("", text: $password)
                                                .textContentType(.password)
                                        }
                                    }
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .accessibilityIdentifier("login.passwordField")
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

                        Button(action: submit) {
                            AuthButtonLabel(
                                title: "Sign in",
                                isLoading: authentication.isSigningIn,
                                isProminent: true
                            )
                        }
                        .accessibilityIdentifier("login.signInButton")
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        .controlSize(.large)
                        .disabled(!hasCredentials)
                        .allowsHitTesting(!authentication.isSigningIn)

                        NavigationLink("Forgot password?", value: AuthenticationRoute.forgotPassword)
                            .font(.callout)
                            .padding(.top, 2)

                        HStack(spacing: 4) {
                            Text("New to Libero?")
                                .foregroundStyle(.secondary)

                            NavigationLink("Create an account", value: AuthenticationRoute.register)
                        }
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    }
                }
                .frame(maxWidth: 380)
                .padding(.horizontal, 36)
                .padding(.top, 108)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.screenBackground)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AuthenticationRoute.self) { route in
                switch route {
                case .forgotPassword:
                    ForgotPasswordView()
                case .register:
                    RegisterView()
                }
            }
            .onSubmit(handleSubmit)
        }
    }

    private func handleSubmit() {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password, nil:
            submit()
        }
    }

    private func togglePasswordVisibility() {
        showPassword.toggle()
        focusedField = .password
    }

    private func submit() {
        guard hasCredentials, !authentication.isSigningIn else {
            return
        }

        let submittedEmail = email
        let submittedPassword = password
        focusedField = nil

        Task {
            await authentication.signIn(email: submittedEmail, password: submittedPassword)

            if authentication.session == nil {
                email = submittedEmail
                password = submittedPassword
            }
        }
    }

    private enum Field {
        case email
        case password
    }
}

private enum AuthenticationRoute: Hashable {
    case forgotPassword
    case register
}

#Preview("Default") {
    LoginView()
        .environment(AuthenticationStore.preview())
}

#Preview("Error") {
    LoginView()
        .environment(AuthenticationStore.preview(errorMessage: "The email or password is incorrect."))
}
