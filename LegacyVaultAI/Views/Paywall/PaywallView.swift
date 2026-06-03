import StoreKit
import SwiftData
import SwiftUI

struct PaywallView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Query(sort: \SubscriptionState.createdAt, order: .reverse) private var storedStates: [SubscriptionState]

    private let plans = [
        PaywallPlan(
            name: "Free",
            price: "£0",
            subtitle: "Basic estate checklist and limited records",
            features: ["Limited assets", "Basic estate checklist", "Limited vault storage"]
        ),
        PaywallPlan(
            name: "Premium",
            price: "£9.99 / month",
            subtitle: "Unlimited organization and premium planning tools",
            features: ["Unlimited assets", "Voice legacy recordings", "Estate readiness engine", "PDF reports", "AI assistant"]
        ),
        PaywallPlan(
            name: "Family Office",
            price: "£24.99 / month",
            subtitle: "Advanced family legacy tools",
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

                if subscriptionService.products.isEmpty == false {
                    PremiumCard {
                        SectionHeader(title: "StoreKit Products", subtitle: "Loaded from StoreKit 2.")
                        ForEach(subscriptionService.products, id: \.id) { product in
                            Button {
                                Task {
                                    try? await subscriptionService.purchase(product)
                                    syncStoredPlan(subscriptionService.displayState.plan, active: subscriptionService.displayState.isActive)
                                }
                            } label: {
                                HStack {
                                    Text(product.displayName)
                                    Spacer()
                                    Text(product.displayPrice)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.legacyIvory)
                        }
                    }
                }

                if let loadingError = subscriptionService.loadingError {
                    ErrorStateView(message: loadingError)
                }

                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
    }

    private func planCard(_ plan: PaywallPlan) -> some View {
        PremiumCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.legacyIvory)
                    Text(plan.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(plan.price)
                    .font(.headline)
                    .foregroundStyle(LegacyTheme.paleGold)
            }

            ForEach(plan.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            planActionButton(plan)
        }
    }

    @ViewBuilder
    private func planActionButton(_ plan: PaywallPlan) -> some View {
        let isSelected = plan.name == subscriptionService.displayState.plan
        if isSelected {
            Button {
                subscriptionService.activateMockPlan(plan.name)
                syncStoredPlan(plan.name, active: plan.name != "Free")
            } label: {
                Label("Selected", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(SecondaryPremiumButtonStyle())
        } else {
            Button {
                subscriptionService.activateMockPlan(plan.name)
                syncStoredPlan(plan.name, active: plan.name != "Free")
            } label: {
                Label("Choose \(plan.name)", systemImage: "crown")
            }
            .buttonStyle(PremiumButtonStyle())
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
    var price: String
    var subtitle: String
    var features: [String]
}
