import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case assets
    case vault
    case voice
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .assets: "Assets"
        case .vault: "Vault"
        case .voice: "Voice"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .assets: "building.columns"
        case .vault: "lock.shield"
        case .voice: "waveform"
        case .settings: "gearshape"
        }
    }
}

enum AppRoute: Hashable {
    case assets
    case beneficiaries
    case digitalVault
    case voice
    case executor
    case guardian
    case finalWishes
    case assistant
    case timeline
    case familyVault
    case documents
    case reports
    case paywall
}

struct RootView: View {
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            AppShellView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}

struct AppShellView: View {
    let profile: UserProfile
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            tabNavigation(title: "LegacyVault AI") {
                DashboardView(profile: profile)
            }
            .tabItem { Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.symbol) }
            .tag(AppTab.dashboard)

            tabNavigation(title: "Asset Inventory") {
                AssetInventoryView()
            }
            .tabItem { Label(AppTab.assets.title, systemImage: AppTab.assets.symbol) }
            .tag(AppTab.assets)

            tabNavigation(title: "Digital Vault") {
                DigitalLegacyVaultView()
            }
            .tabItem { Label(AppTab.vault.title, systemImage: AppTab.vault.symbol) }
            .tag(AppTab.vault)

            tabNavigation(title: "Voice Legacy") {
                VoiceLegacyRecorderView()
            }
            .tabItem { Label(AppTab.voice.title, systemImage: AppTab.voice.symbol) }
            .tag(AppTab.voice)

            tabNavigation(title: "Settings") {
                SettingsView()
            }
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbol) }
            .tag(AppTab.settings)
        }
        .tint(.legacyGold)
    }

    private func tabNavigation<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .assets:
            AssetInventoryView()
        case .beneficiaries:
            BeneficiaryManagementView()
        case .digitalVault:
            DigitalLegacyVaultView()
        case .voice:
            VoiceLegacyRecorderView()
        case .executor:
            ExecutorDashboardView()
        case .guardian:
            GuardianPlanningView()
        case .finalWishes:
            FinalWishesPlannerView()
        case .assistant:
            AIEstateAssistantView()
        case .timeline:
            LegacyTimelineView()
        case .familyVault:
            FamilyLegacyVaultView()
        case .documents:
            DocumentVaultView()
        case .reports:
            EstateReviewReportsView()
        case .paywall:
            PaywallView()
        }
    }
}
