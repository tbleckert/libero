//
//  LiberoApp.swift
//  Libero
//
//  Created by Tobias Bleckert on 2026-06-29.
//

import SwiftUI

@main
struct LiberoApp: App {
    @State private var startupState: StartupState

    init() {
        AppTheme.applyGlobalAppearance()

        do {
            let configuration = try AppConfiguration.current()
            _startupState = State(
                initialValue: .ready(AuthenticationStore(apiClient: APIClient(configuration: configuration)))
            )
        } catch {
            _startupState = State(initialValue: .failed(error.localizedDescription))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch startupState {
            case .ready(let authentication):
                ContentView()
                    .environment(authentication)
                    .tint(AppTheme.primaryColor)
            case .failed(let message):
                ContentUnavailableView(
                    "Libero is not configured",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .tint(AppTheme.primaryColor)
            }
        }
    }
}

private enum StartupState {
    case ready(AuthenticationStore)
    case failed(String)
}
