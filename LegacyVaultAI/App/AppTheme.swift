import SwiftUI

enum LegacyTheme {
    static let cornerRadius: CGFloat = 8
    static let gold = Color(red: 0.82, green: 0.64, blue: 0.31)
    static let paleGold = Color(red: 0.95, green: 0.84, blue: 0.56)
    static let navy = Color(red: 0.03, green: 0.07, blue: 0.12)
    static let deepNavy = Color(red: 0.015, green: 0.03, blue: 0.06)
    static let charcoal = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let slate = Color(red: 0.30, green: 0.34, blue: 0.39)
    static let ivory = Color(red: 0.94, green: 0.92, blue: 0.86)
    static let green = Color(red: 0.26, green: 0.62, blue: 0.48)
    static let ruby = Color(red: 0.70, green: 0.24, blue: 0.30)

    static var dashboardGradient: LinearGradient {
        LinearGradient(
            colors: [deepNavy, navy, charcoal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    static let legacyGold = LegacyTheme.gold
    static let legacyNavy = LegacyTheme.navy
    static let legacyCharcoal = LegacyTheme.charcoal
    static let legacyIvory = LegacyTheme.ivory
}

extension View {
    func premiumSurface() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LegacyTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LegacyTheme.cornerRadius, style: .continuous)
                    .stroke(LegacyTheme.gold.opacity(0.22), lineWidth: 1)
            )
    }

    func premiumScreenBackground() -> some View {
        self
            .background(LegacyTheme.dashboardGradient.ignoresSafeArea())
            .scrollContentBackground(.hidden)
    }
}
