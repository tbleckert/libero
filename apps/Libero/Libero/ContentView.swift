//
//  ContentView.swift
//  Libero
//
//  Created by Tobias Bleckert on 2026-06-29.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationStore.self) private var authentication

    var body: some View {
        Group {
            if let session = authentication.session {
                if session.user.shouldVerifyEmail {
                    EmailVerificationView(session: session)
                } else {
                    AuthenticatedHomeView(session: session)
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationStore.preview())
}
