import Foundation

struct LegacyVaultWatchPlaceholder {
    enum WatchSurface: String, CaseIterable, Identifiable {
        case reminders = "Estate Review Reminders"
        case vaultAlerts = "Vault Alerts"
        case readinessSnapshot = "Readiness Snapshot"

        var id: String { rawValue }
    }

    static let bundleIdentifier = "com.legacyvaultai.watch"
    static let surfaces = WatchSurface.allCases
    static let implementationNote = "Apple Watch target placeholder for reminders, vault alerts, and readiness snapshots."
}
