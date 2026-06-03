import SwiftData
import SwiftUI

@main
struct LegacyVaultAIApp: App {
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var securityViewModel = SecurityViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptionService)
                .environmentObject(securityViewModel)
                .preferredColorScheme(.dark)
                .task {
                    await subscriptionService.loadProducts()
                    await subscriptionService.refreshEntitlements()
                }
        }
        .modelContainer(for: [
            UserProfile.self,
            Asset.self,
            Beneficiary.self,
            Executor.self,
            DigitalAsset.self,
            VoiceLegacyRecording.self,
            EstateReview.self,
            SubscriptionState.self,
            GuardianPlan.self,
            FinalWishesPlan.self,
            LegacyTimelineEvent.self,
            FamilyLegacyItem.self,
            DocumentRecord.self
        ])
    }
}
