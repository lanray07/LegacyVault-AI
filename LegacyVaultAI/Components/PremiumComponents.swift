import Charts
import SwiftUI

struct PremiumCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
    }
}

struct LegalDisclaimerBanner: View {
    var compact = false

    var body: some View {
        PremiumCard {
            Label("Educational guidance only", systemImage: "scale.3d")
                .font(.headline)
                .foregroundStyle(LegacyTheme.paleGold)
            if compact {
                Text(LegalDisclaimer.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(LegalDisclaimer.bullets, id: \.self) { bullet in
                        Label(bullet, systemImage: "checkmark.shield")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityIdentifier("legalDisclaimerBanner")
    }
}

struct ReadinessScoreRing: View {
    var score: Int
    var label: String = "Estate Readiness"

    private var progress: Double {
        Double(score) / 100
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(LegacyTheme.slate.opacity(0.3), lineWidth: 16)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [LegacyTheme.gold, LegacyTheme.green, LegacyTheme.paleGold], center: .center),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.85), value: score)
            VStack(spacing: 4) {
                Text("\(score)%")
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundStyle(Color.legacyIvory)
                Text(label)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 172, height: 172)
        .accessibilityLabel("\(label), \(score) percent")
    }
}

struct AssetCard: View {
    var asset: Asset
    private let formatter = AssetAnalysisService()

    var body: some View {
        PremiumCard {
            HStack(alignment: .top) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(LegacyTheme.gold)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 6) {
                    Text(asset.title.isEmpty ? asset.assetType : asset.title)
                        .font(.headline)
                        .foregroundStyle(Color.legacyIvory)
                    Text(asset.assetType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formatter.formattedCurrency(asset.estimatedValue))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(LegacyTheme.paleGold)
                    if asset.location.isEmpty == false {
                        Label(asset.location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var symbol: String {
        switch asset.assetType {
        case "Property": "house.and.flag"
        case "Bank account": "banknote"
        case "Investment": "chart.line.uptrend.xyaxis"
        case "Pension": "briefcase"
        case "Vehicle": "car"
        case "Business": "building.2"
        case "Collectible": "diamond"
        case "Crypto placeholder": "bitcoinsign.circle"
        default: "archivebox"
        }
    }
}

struct BeneficiaryCard: View {
    var beneficiary: Beneficiary

    var body: some View {
        PremiumCard {
            HStack(alignment: .top) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(LegacyTheme.gold)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 6) {
                    Text(beneficiary.name.isEmpty ? "Unnamed beneficiary" : beneficiary.name)
                        .font(.headline)
                        .foregroundStyle(Color.legacyIvory)
                    Text(beneficiary.relationship.isEmpty ? "Relationship not set" : beneficiary.relationship)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if beneficiary.allocationNote.isEmpty == false {
                        Text(beneficiary.allocationNote)
                            .font(.caption)
                            .foregroundStyle(LegacyTheme.paleGold)
                    }
                }
                Spacer()
            }
        }
    }
}

struct VaultCard: View {
    var title: String
    var subtitle: String
    var symbol: String
    var locked: Bool = true

    var body: some View {
        PremiumCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LegacyTheme.gold.opacity(0.16))
                    Image(systemName: symbol)
                        .font(.title2)
                        .foregroundStyle(LegacyTheme.paleGold)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.legacyIvory)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "lock.open.fill")
                    .foregroundStyle(locked ? LegacyTheme.gold : LegacyTheme.green)
            }
        }
    }
}

struct VoiceWaveformView: View {
    var levels: [CGFloat]
    var isRecording: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(isRecording ? LegacyTheme.gold : LegacyTheme.slate.opacity(0.65))
                    .frame(width: 4, height: max(10, level * 86))
                    .animation(.easeInOut(duration: 0.12), value: level)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(.vertical, 12)
        .premiumSurface()
        .accessibilityLabel(isRecording ? "Recording waveform active" : "Recording waveform idle")
    }
}

struct EstateReviewCard: View {
    var title: String
    var summary: String
    var score: Int?

    var body: some View {
        PremiumCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.legacyIvory)
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let score {
                    Text("\(score)%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(LegacyTheme.paleGold)
                }
            }
            Divider().overlay(LegacyTheme.gold.opacity(0.35))
            Text(LegalDisclaimer.short)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct AnalyticsChartCard: View {
    var metrics: [EstateMetric]

    var body: some View {
        PremiumCard {
            Label("Estate Analytics", systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(Color.legacyIvory)
            Chart(metrics) { metric in
                BarMark(
                    x: .value("Area", metric.title),
                    y: .value("Count", metric.value)
                )
                .foregroundStyle(color(for: metric.tintName))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let title = value.as(String.self) {
                            Text(title)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
    }

    private func color(for name: String) -> Color {
        switch name {
        case "green": LegacyTheme.green
        case "blue": Color.cyan
        case "ivory": LegacyTheme.ivory
        default: LegacyTheme.gold
        }
    }
}

struct ReportPreviewView: View {
    var snapshot: EstateReadinessSnapshot
    var assetsCount: Int
    var beneficiariesCount: Int
    var documentsCount: Int

    var body: some View {
        PremiumCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estate Review Report")
                        .font(.headline)
                        .foregroundStyle(Color.legacyIvory)
                    Text("Summary, asset inventory, beneficiary overview, readiness report, and legacy notes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "doc.richtext")
                    .font(.largeTitle)
                    .foregroundStyle(LegacyTheme.gold)
            }
            HStack {
                reportStat("Score", "\(snapshot.score)%")
                reportStat("Assets", "\(assetsCount)")
                reportStat("People", "\(beneficiariesCount)")
                reportStat("Docs", "\(documentsCount)")
            }
        }
    }

    private func reportStat(_ title: String, _ value: String) -> some View {
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
}

struct UpgradeBanner: View {
    var plan: String

    var body: some View {
        NavigationLink(value: AppRoute.paywall) {
            HStack(spacing: 12) {
                Image(systemName: "crown")
                    .foregroundStyle(LegacyTheme.paleGold)
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan == "Free" ? "Unlock Premium Planning" : "\(plan) active")
                        .font(.headline)
                        .foregroundStyle(Color.legacyIvory)
                    Text(plan == "Free" ? "Voice recordings, PDF reports, AI reviews, and unlimited records." : "Your subscription features are enabled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .premiumSurface()
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var symbol: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(LegacyTheme.gold)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.legacyIvory)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .premiumSurface()
    }
}

struct LoadingStateView: View {
    var message: String

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(LegacyTheme.gold)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSurface()
    }
}

struct ErrorStateView: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(LegacyTheme.ruby)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumSurface()
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.legacyIvory)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(LegacyTheme.deepNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(LegacyTheme.gold.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryPremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.legacyIvory)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(LegacyTheme.charcoal.opacity(configuration.isPressed ? 0.85 : 0.6), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(LegacyTheme.gold.opacity(0.3), lineWidth: 1)
            )
    }
}
