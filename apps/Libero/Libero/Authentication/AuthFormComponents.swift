//
//  AuthFormComponents.swift
//  Libero
//
//  Created by Codex on 2026-06-29.
//

import SwiftUI

struct AuthButtonLabel: View {
    let title: String
    let isLoading: Bool
    let isProminent: Bool

    init(title: String, isLoading: Bool, isProminent: Bool = false) {
        self.title = title
        self.isLoading = isLoading
        self.isProminent = isProminent
    }

    var body: some View {
        ZStack {
            Text(L10n.string(title, fallback: title))
                .fontWeight(.semibold)
                .foregroundStyle(contentColor)
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(contentColor)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 20)
    }

    private var contentColor: Color {
        isProminent ? AppTheme.primaryContentColor : .primary
    }
}

struct AuthHeader: View {
    let subtitle: String

    var body: some View {
        VStack(spacing: 28) {
            Text("Libero")
                .font(.system(size: 64, weight: .medium, design: .serif))
                .tracking(0)

            Divider()
                .frame(width: 48)

            Text(L10n.string(subtitle, fallback: subtitle))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: 288)
        }
    }
}

struct AuthMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("auth.message")
    }
}

struct LabeledAuthField<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string(title, fallback: title))
                .font(.subheadline.weight(.medium))

            content
        }
    }
}

struct AuthInputContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .font(.body)
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .colorScheme(.light)
    }
}

struct AuthPlaceholderText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(L10n.string(text, fallback: text))
            .foregroundStyle(Color(.placeholderText))
            .allowsHitTesting(false)
    }
}
