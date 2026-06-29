//
//  AuthenticatedHomeView.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI

struct AuthenticatedHomeView: View {
    @Environment(AuthenticationStore.self) private var authentication
    let session: AuthSession

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryColor)

                VStack(spacing: 8) {
                    Text("Welcome, \(session.user.name)")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text(session.user.email)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Button("Sign out", action: signOut)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .controlSize(.large)
                    .padding(.top, 12)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.screenBackground)
            .navigationTitle("Libero")
        }
        .task {
            _ = try? await authentication.currentUser(for: session)
        }
    }

    private func signOut() {
        Task {
            await authentication.signOut()
        }
    }
}

#Preview {
    AuthenticatedHomeView(session: .preview)
        .environment(AuthenticationStore.preview(session: .preview))
}
