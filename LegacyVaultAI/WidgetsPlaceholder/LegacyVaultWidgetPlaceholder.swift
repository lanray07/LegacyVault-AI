import Foundation

struct LegacyVaultWidgetPlaceholder {
    enum WidgetKind: String, CaseIterable, Identifiable {
        case readinessScore = "Readiness Score"
        case reviewReminder = "Review Reminder"
        case vaultShortcut = "Vault Shortcut"

        var id: String { rawValue }
    }

    static let bundleIdentifier = "com.legacyvaultai.app.widgets"
    static let supportedWidgets = WidgetKind.allCases
    static let implementationNote = "WidgetKit extension placeholder for readiness score, review reminder, and secure vault shortcut widgets."
}
