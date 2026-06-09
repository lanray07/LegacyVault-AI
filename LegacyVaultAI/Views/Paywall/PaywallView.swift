import StoreKit
import SwiftData
import SwiftUI

struct PaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Query(sort: \SubscriptionState.createdAt, order: .reverse) private var storedStates: [SubscriptionState]

    @State private var purchasingProductID: String?
    @State private var isRestoring = false

    private let plans = [
        PaywallPlan(
            name: "Free",
            entitlementName: "Free",
            productID: nil,
            fallbackPrice: "Free",
            duration: "No subscription",
            subtitle: "Basic estate checklist and limited records.",
            features: ["Limited assets", "Basic estate checklist", "Limited vault storage"]
        ),
        PaywallPlan(
            name: "Premium Monthly",
            entitlementName: "Premium",
            productID: SubscriptionService.premiumMonthlyID,
            fallbackPrice: "Monthly subscription",
            duration: "Renews monthly",
            subtitle: "Unlimited organization and premium planning tools.",
            features: ["Unlimited assets", "Voice legacy recordings", "Estate readiness engine", "PDF reports", "AI assistant"]
        ),
        PaywallPlan(
            name: "Premium Yearly",
            entitlementName: "Premium",
            productID: SubscriptionService.premiumYearlyID,
            fallbackPrice: "Annual subscription",
            duration: "Renews yearly",
            subtitle: "A full year of premium planning for organized family records.",
            features: ["Unlimited assets", "Voice legacy recordings", "Estate readiness engine", "PDF reports", "AI assistant"]
        ),
        PaywallPlan(
            name: "Family Office Monthly",
            entitlementName: "Family Office",
            productID: SubscriptionService.familyOfficeMonthlyID,
            fallbackPrice: "Monthly subscription",
            duration: "Renews monthly",
            subtitle: "Advanced family legacy tools and shared planning placeholders.",
            features: ["Multiple family members", "Shared vault placeholder", "Advanced reports", "Premium legacy tools"]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PremiumCard {
                    SectionHeader(title: "LegacyVault AI Plans", subtitle: "Premium estate organization, voice legacy recordings, reports, and AI insights.")
                    Label("Current plan: \(subscriptionService.displayState.plan)", systemImage: "crown")
                        .font(.headline)
                        .foregroundStyle(LegacyTheme.paleGold)
                }

                ForEach(plans) { plan in
                    planCard(plan)
                }

                managePurchasesCard

                if let loadingError = subscriptionService.loadingError {
                    ErrorStateView(message: loadingError)
                }

                legalLinksCard
                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .task {
            if subscriptionService.products.isEmpty {
                await subscriptionService.loadProducts()
            }
            await subscriptionService.refreshEntitlements()
            syncStoredPlan(subscriptionService.displayState.plan, active: subscriptionService.displayState.isActive)
        }
    }

    private func planCard(_ plan: PaywallPlan) -> some View {
        let product = product(for: plan)
        let isSelected = subscriptionService.displayState.isActive
            ? plan.entitlementName == subscriptionService.displayState.plan
            : plan.productID == nil

        return PremiumCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.legacyIvory)
                    Text(plan.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product?.displayPrice ?? plan.fallbackPrice)
                        .font(.headline)
                        .foregroundStyle(LegacyTheme.paleGold)
                    Text(plan.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(plan.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            planActionButton(plan, product: product, isSelected: isSelected)
        }
    }

    private var managePurchasesCard: some View {
        PremiumCard {
            SectionHeader(title: "Manage Purchases", subtitle: "Purchases are processed securely through your Apple ID.")

            if let statusMessage = subscriptionService.statusMessage {
                Label(statusMessage, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                restorePurchases()
            } label: {
                if isRestoring {
                    Label("Restoring Purchases", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    Label("Restore Purchases", systemImage: "arrow.clockwise.circle")
                }
            }
            .buttonStyle(SecondaryPremiumButtonStyle())
            .disabled(isRestoring || purchasingProductID != nil)
        }
    }

    private var legalLinksCard: some View {
        PremiumCard {
            SectionHeader(title: "Subscription Terms", subtitle: "Required policy links for auto-renewable subscriptions.")
            Link(destination: LegalLinks.privacyPolicy) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            .foregroundStyle(Color.legacyIvory)

            Link(destination: LegalLinks.termsOfUse) {
                Label("Terms of Use (EULA)", systemImage: "doc.text")
            }
            .foregroundStyle(Color.legacyIvory)

            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel subscriptions in your Apple ID settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func planActionButton(_ plan: PaywallPlan, product: Product?, isSelected: Bool) -> some View {
        if isSelected {
            Button {} label: {
                Label("Selected", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(SecondaryPremiumButtonStyle())
            .disabled(true)
        } else if plan.productID == nil {
            Button {
                subscriptionService.activateMockPlan("Free")
                syncStoredPlan("Free", active: false)
            } label: {
                Label("Use Free Plan", systemImage: "checkmark.circle")
            }
            .buttonStyle(SecondaryPremiumButtonStyle())
            .disabled(purchasingProductID != nil || isRestoring)
        } else if let product {
            Button {
                purchase(product)
            } label: {
                if purchasingProductID == product.id {
                    Label("Opening Purchase", systemImage: "hourglass")
                } else {
                    Label("Purchase \(plan.name)", systemImage: "crown")
                }
            }
            .buttonStyle(PremiumButtonStyle())
            .disabled(purchasingProductID != nil || isRestoring)
        } else {
            Label("Subscription unavailable", systemImage: "wifi.exclamationmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func product(for plan: PaywallPlan) -> Product? {
        guard let productID = plan.productID else { return nil }
        return subscriptionService.products.first { $0.id == productID }
    }

    private func purchase(_ product: Product) {
        purchasingProductID = product.id
        Task {
            defer { purchasingProductID = nil }
            do {
                try await subscriptionService.purchase(product)
                syncStoredPlan(subscriptionService.displayState.plan, active: subscriptionService.displayState.isActive)
            } catch {
                subscriptionService.loadingError = "Unable to complete purchase. Please try again."
                subscriptionService.statusMessage = nil
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true
        Task {
            defer { isRestoring = false }
            await subscriptionService.restorePurchases()
            syncStoredPlan(subscriptionService.displayState.plan, active: subscriptionService.displayState.isActive)
        }
    }

    private func syncStoredPlan(_ plan: String, active: Bool) {
        if let state = storedStates.first {
            state.plan = plan
            state.isActive = active
            state.renewalDate = active ? Calendar.current.date(byAdding: .month, value: 1, to: .now) : nil
        } else {
            modelContext.insert(SubscriptionState(plan: plan, isActive: active, renewalDate: active ? Calendar.current.date(byAdding: .month, value: 1, to: .now) : nil))
        }
        try? modelContext.save()
    }
}

private struct PaywallPlan: Identifiable {
    let id = UUID()
    var name: String
    var entitlementName: String
    var productID: String?
    var fallbackPrice: String
    var duration: String
    var subtitle: String
    var features: [String]
}
