//
//  AppTheme.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppTheme {
    static let primaryColor = Color.accentColor

    static var primaryContentColor: Color {
        platformColor(.systemBackground)
    }

    static var screenBackground: Color {
        platformColor(.systemGroupedBackground)
    }

    static var fieldBackground: Color {
        platformColor(.secondarySystemBackground)
    }

    static func applyGlobalAppearance() {
        #if canImport(UIKit)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        #endif
    }

    private static func platformColor(_ color: PlatformColor) -> Color {
        #if canImport(UIKit)
        Color(uiColor: color)
        #else
        Color(color)
        #endif
    }
}

#if canImport(UIKit)
private typealias PlatformColor = UIColor
#else
private typealias PlatformColor = NSColor
#endif
