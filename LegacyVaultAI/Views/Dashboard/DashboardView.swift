import SwiftData
import SwiftUI

struct DashboardView: View {
    let profile: UserProfile

    @EnvironmentObject private var subscriptionService: SubscriptionService
    @StateObject private var viewModel = DashboardViewModel()
    @Query(sort: \Asset.createdAt, order: .reverse) private var assets: [Asset]
    @Query(sort: \Beneficiary.createdAt, order: .reverse) private var beneficiaries: [Beneficiary]
    @Query(sort: \Executor.createdAt, order: .reverse) private var executors: [Executor]
    @Query(sort: \DigitalAsset.createdAt, order: .reverse) private var digitalAssets: [DigitalAsset]
    @Query(sort: \GuardianPlan.createdAt, order: .reverse) private var guardians: [GuardianPlan]
    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]
    @Query(sort: \VoiceLegacyRecording.createdAt, order: .reverse) private var recordings: [VoiceLegacyRecording]

    private let assetService = AssetAnalysisService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topSummary
                UpgradeBanner(plan: subscriptionService.displayState.plan)
                quickActions
                readinessDetails
                AnalyticsChartCard(metrics: assetService.metrics(assets: assets, digitalAssets: digitalAssets, documents: documents, beneficiaries: beneficiaries))
                recommendations
                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .task { refresh() }
        .onAppear { refresh() }
    }

    private var topSummary: some View {
        PremiumCard {
            HStack(alignment: .center, spacing: 18) {
                ReadinessScoreRing(score: viewModel.snapshot.score)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Family readiness overview")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.legacyIvory)
                    Text("Your vault combines estate organization, family legacy notes, digital asset coverage, and review reminders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        stat("Assets", "\(assets.count)")
                        stat("Beneficiaries", "\(beneficiaries.count)")
                        stat("Docs", "\(documents.count)")
                    }
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Actions", subtitle: "Move the estate profile forward.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                action("Add Asset", "plus.circle", .assets)
                action("Create Legacy Plan", "sparkles", .assistant)
                action("Record Wishes", "waveform.circle", .voice)
                action("Add Beneficiary", "person.badge.plus", .beneficiaries)
                action("Digital Vault", "lock.shield", .digitalVault)
                action("Estate Review", "doc.richtext", .reports)
            }
        }
    }

    private var readinessDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Readiness Engine", subtitle: "Calculated from documents, beneficiaries, executors, digital assets, guardians, insurance, and record completeness.")
            if viewModel.snapshot.missingItems.isEmpty {
                EstateReviewCard(title: "No critical gaps detected", summary: "Keep annual legal and financial reviews current.", score: viewModel.snapshot.score)
            } else {
                ForEach(viewModel.snapshot.missingItems.prefix(4), id: \.self) { item in
                    EstateReviewCard(title: item, summary: "Add or review this area to improve readiness.", score: nil)
                }
            }
        }
    }

    private var recommendations: some View {
        PremiumCard {
            Label("AI Recommendations", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.legacyIvory)
            ForEach(viewModel.roadmap, id: \.self) { step in
                Label(step, systemImage: "arrow.up.forward.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider().overlay(LegacyTheme.gold.opacity(0.25))
            Text(viewModel.alerts.joined(separator: "\n"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(LegacyTheme.paleGold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(LegacyTheme.charcoal.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
    }

    private func action(_ title: String, _ symbol: String, _ route: AppRoute) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(LegacyTheme.gold)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.legacyIvory)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer()
            }
            .padding(14)
            .frame(minHeight: 62)
            .premiumSurface()
        }
        .buttonStyle(.plain)
    }

    private func refresh() {
        viewModel.refresh(
            profile: profile,
            assets: assets,
            beneficiaries: beneficiaries,
            executors: executors,
            digitalAssets: digitalAssets,
            guardians: guardians,
            documents: documents,
            recordings: recordings
        )
    }
}
