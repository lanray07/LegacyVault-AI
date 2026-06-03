import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var securityViewModel: SecurityViewModel
    @EnvironmentObject private var subscriptionService: SubscriptionService

    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \Asset.createdAt) private var assets: [Asset]
    @Query(sort: \Beneficiary.createdAt) private var beneficiaries: [Beneficiary]
    @Query(sort: \Executor.createdAt) private var executors: [Executor]
    @Query(sort: \DigitalAsset.createdAt) private var digitalAssets: [DigitalAsset]
    @Query(sort: \VoiceLegacyRecording.createdAt) private var recordings: [VoiceLegacyRecording]
    @Query(sort: \EstateReview.createdAt) private var reviews: [EstateReview]
    @Query(sort: \SubscriptionState.createdAt) private var subscriptionStates: [SubscriptionState]
    @Query(sort: \GuardianPlan.createdAt) private var guardians: [GuardianPlan]
    @Query(sort: \FinalWishesPlan.createdAt) private var finalWishes: [FinalWishesPlan]
    @Query(sort: \LegacyTimelineEvent.createdAt) private var timelineEvents: [LegacyTimelineEvent]
    @Query(sort: \FamilyLegacyItem.createdAt) private var legacyItems: [FamilyLegacyItem]
    @Query(sort: \DocumentRecord.createdAt) private var documents: [DocumentRecord]

    @State private var notificationStatus = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Settings", subtitle: "Subscription, security, notifications, exports, privacy, terms, and legal disclaimer.")
                    Label("Plan: \(subscriptionService.displayState.plan)", systemImage: "crown")
                        .font(.headline)
                        .foregroundStyle(LegacyTheme.paleGold)
                }

                NavigationLink(value: AppRoute.paywall) {
                    settingsRow("Subscription", "Manage Premium and Family Office placeholders", "creditcard")
                }
                .buttonStyle(.plain)

                securityCard
                notificationCard
                exportCard
                legalCard
                deleteCard
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .alert("Delete all LegacyVault AI data?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes local SwiftData records from this device.")
        }
    }

    private var securityCard: some View {
        PremiumCard {
            SectionHeader(title: "Biometric Security", subtitle: "Face ID and Touch ID architecture for vault unlock.")
            Label(securityViewModel.statusMessage, systemImage: securityViewModel.isUnlocked ? "lock.open" : "lock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    Task { await securityViewModel.enableBiometrics() }
                } label: {
                    Label("Enable \(securityViewModel.biometricLabel)", systemImage: "faceid")
                }
                .buttonStyle(PremiumButtonStyle())

                Button {
                    if securityViewModel.isUnlocked {
                        securityViewModel.lock()
                    } else {
                        Task { await securityViewModel.unlock() }
                    }
                } label: {
                    Label(securityViewModel.isUnlocked ? "Lock Vault" : "Unlock Vault", systemImage: securityViewModel.isUnlocked ? "lock" : "lock.open")
                }
                .buttonStyle(SecondaryPremiumButtonStyle())
            }
        }
    }

    private var notificationCard: some View {
        PremiumCard {
            SectionHeader(title: "Notifications", subtitle: "Annual review reminders and vault alert placeholders.")
            if notificationStatus.isEmpty == false {
                Text(notificationStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                Task {
                    let service = NotificationService()
                    let granted = await service.requestAuthorization()
                    if granted {
                        try? await service.scheduleAnnualReviewReminder()
                        notificationStatus = "Annual estate review reminder scheduled."
                    } else {
                        notificationStatus = "Notifications were not authorized."
                    }
                }
            } label: {
                Label("Schedule Annual Review", systemImage: "bell.badge")
            }
            .buttonStyle(PremiumButtonStyle())
        }
    }

    private var exportCard: some View {
        PremiumCard {
            SectionHeader(title: "Export Settings", subtitle: "PDF reports and native share sheet.")
            NavigationLink(value: AppRoute.reports) {
                settingsRow("Estate Review Reports", "Generate PDF summaries for family and professional review", "doc.richtext")
            }
            .buttonStyle(.plain)
            NavigationLink(value: AppRoute.documents) {
                settingsRow("Document Vault", "Review secure document architecture placeholders", "lock.doc")
            }
            .buttonStyle(.plain)
        }
    }

    private var legalCard: some View {
        PremiumCard {
            SectionHeader(title: "Privacy, Terms & Legal Disclaimer", subtitle: "Required estate-planning guardrails.")
            ForEach(LegalDisclaimer.bullets, id: \.self) { bullet in
                Label(bullet, systemImage: "checkmark.shield")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Divider().overlay(LegacyTheme.gold.opacity(0.25))
            Text("Privacy policy and terms of use screens are ready for production legal copy.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var deleteCard: some View {
        PremiumCard {
            SectionHeader(title: "Data", subtitle: "Offline-friendly local storage using SwiftData.")
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundStyle(LegacyTheme.ruby)
            }
            .buttonStyle(SecondaryPremiumButtonStyle())
        }
    }

    private func settingsRow(_ title: String, _ subtitle: String, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(LegacyTheme.gold)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.legacyIvory)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(LegacyTheme.charcoal.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }

    private func deleteAllData() {
        profiles.forEach { modelContext.delete($0) }
        assets.forEach { modelContext.delete($0) }
        beneficiaries.forEach { modelContext.delete($0) }
        executors.forEach { modelContext.delete($0) }
        digitalAssets.forEach { modelContext.delete($0) }
        recordings.forEach { modelContext.delete($0) }
        reviews.forEach { modelContext.delete($0) }
        subscriptionStates.forEach { modelContext.delete($0) }
        guardians.forEach { modelContext.delete($0) }
        finalWishes.forEach { modelContext.delete($0) }
        timelineEvents.forEach { modelContext.delete($0) }
        legacyItems.forEach { modelContext.delete($0) }
        documents.forEach { modelContext.delete($0) }
        subscriptionService.activateMockPlan("Free")
        try? modelContext.save()
    }
}
