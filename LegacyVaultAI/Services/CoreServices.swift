import Foundation
import Combine
import StoreKit
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct EstateReviewService {
    func calculateReadiness(
        profile: UserProfile?,
        assets: [Asset],
        beneficiaries: [Beneficiary],
        executors: [Executor],
        digitalAssets: [DigitalAsset],
        guardians: [GuardianPlan],
        documents: [DocumentRecord],
        recordings: [VoiceLegacyRecording]
    ) -> EstateReadinessSnapshot {
        var score = 0
        var missingItems: [String] = []
        var improvements: [String] = []

        if profile != nil {
            score += 10
        } else {
            missingItems.append("Legacy profile")
            improvements.append("Complete onboarding to create a baseline estate profile.")
        }

        if assets.isEmpty {
            missingItems.append("Asset inventory")
            improvements.append("Add property, bank, pension, investment, business, vehicle, collectible, and crypto placeholder records.")
        } else {
            score += min(20, assets.count * 4)
        }

        if beneficiaries.isEmpty {
            missingItems.append("Beneficiary details")
            improvements.append("Add beneficiaries and allocation notes for family clarity.")
        } else {
            score += min(15, beneficiaries.count * 5)
        }

        if executors.isEmpty {
            missingItems.append("Executor designation")
            improvements.append("Store executor contact details and a practical responsibility checklist.")
        } else {
            score += 15
        }

        if digitalAssets.isEmpty {
            missingItems.append("Digital asset coverage")
            improvements.append("Document online accounts, subscriptions, domains, social platforms, cloud storage, digital businesses, and wallet placeholders.")
        } else {
            score += min(12, digitalAssets.count * 3)
        }

        let hasWill = documents.contains { $0.documentType.localizedCaseInsensitiveContains("will") }
        let hasInsurance = documents.contains { $0.documentType.localizedCaseInsensitiveContains("insurance") }
        let hasIdentity = documents.contains { $0.documentType.localizedCaseInsensitiveContains("identification") || $0.documentType.localizedCaseInsensitiveContains("identity") }

        if hasWill {
            score += 10
        } else {
            missingItems.append("Will or trust document location")
            improvements.append("Record the location and review status of existing legal documents. Do not rely on this app to create legally binding documents.")
        }

        if hasInsurance {
            score += 5
        } else {
            missingItems.append("Insurance records")
            improvements.append("Add life, home, business, or other insurance record locations.")
        }

        if hasIdentity {
            score += 4
        } else {
            missingItems.append("Identification records")
        }

        if let profile, profile.dependents > 0 {
            if guardians.isEmpty {
                missingItems.append("Guardian planning")
                improvements.append("Add guardian and backup guardian preferences for dependents.")
            } else {
                score += 8
            }
        } else {
            score += 4
        }

        if recordings.isEmpty {
            improvements.append("Record personal wishes or executor context using Voice Legacy.")
        } else {
            score += min(8, recordings.count * 4)
        }

        if missingItems.isEmpty {
            improvements.append("Schedule an annual review and keep professional legal review dates current.")
        }

        return EstateReadinessSnapshot(
            score: min(score, 100),
            missingItems: missingItems,
            improvements: improvements
        )
    }
}

struct AssetAnalysisService {
    func totalValue(assets: [Asset]) -> Double {
        assets.reduce(0) { $0 + $1.estimatedValue }
    }

    func metrics(assets: [Asset], digitalAssets: [DigitalAsset], documents: [DocumentRecord], beneficiaries: [Beneficiary]) -> [EstateMetric] {
        [
            EstateMetric(title: "Assets", value: Double(assets.count), tintName: "gold"),
            EstateMetric(title: "Beneficiaries", value: Double(beneficiaries.count), tintName: "green"),
            EstateMetric(title: "Digital", value: Double(digitalAssets.count), tintName: "blue"),
            EstateMetric(title: "Documents", value: Double(documents.count), tintName: "ivory")
        ]
    }

    func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "GBP"
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

struct LegacyPlanningService {
    func roadmap(profile: UserProfile?, snapshot: EstateReadinessSnapshot) -> [String] {
        var steps = snapshot.improvements
        if let profile, profile.ownsBusiness {
            steps.append("Add business ownership notes, succession context, and key adviser contacts.")
        }
        if let profile, profile.hasDigitalAssets {
            steps.append("Prioritize digital legacy instructions and emergency contacts for online accounts.")
        }
        steps.append("Book qualified legal review before relying on any estate-planning output.")
        return Array(steps.prefix(5))
    }
}

struct EstateInsightService {
    func alerts(snapshot: EstateReadinessSnapshot) -> [String] {
        if snapshot.score < 40 {
            return ["Critical organization gaps remain.", "Start with beneficiaries, executor, and document locations.", LegalDisclaimer.short]
        }

        if snapshot.score < 75 {
            return ["Your estate organization is progressing.", "Close the remaining missing items and export a review report.", LegalDisclaimer.short]
        }

        return ["Strong readiness profile.", "Maintain annual reviews and professional validation.", LegalDisclaimer.short]
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    struct DisplayState: Hashable {
        var plan: String = "Free"
        var isActive: Bool = false
    }

    static let premiumMonthlyID = "com.legacyvaultai.premium.monthly"
    static let premiumYearlyID = "com.legacyvaultai.premium.yearly"
    static let familyOfficeMonthlyID = "com.legacyvaultai.familyoffice.monthly"

    @Published var products: [Product] = []
    @Published var displayState = DisplayState()
    @Published var loadingError: String?

    private let productIDs = [
        premiumMonthlyID,
        premiumYearlyID,
        familyOfficeMonthlyID
    ]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            loadingError = "StoreKit products are using local placeholders until App Store Connect is configured."
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                displayState = DisplayState(plan: planName(for: transaction.productID), isActive: true)
            }
        case .pending, .userCancelled:
            break
        @unknown default:
            break
        }
    }

    func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                displayState = DisplayState(plan: planName(for: transaction.productID), isActive: true)
                return
            }
        }
        displayState = DisplayState(plan: "Free", isActive: false)
    }

    func activateMockPlan(_ plan: String) {
        displayState = DisplayState(plan: plan, isActive: plan != "Free")
    }

    private func planName(for productID: String) -> String {
        switch productID {
        case Self.premiumMonthlyID, Self.premiumYearlyID:
            "Premium"
        case Self.familyOfficeMonthlyID:
            "Family Office"
        default:
            "Free"
        }
    }
}

struct NotificationService {
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleAnnualReviewReminder() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Estate review reminder"
        content.body = "Review your LegacyVault AI profile and consult qualified professionals where needed."
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.month, .day], from: .now)
        dateComponents.hour = 9

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "annual-estate-review", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }
}

struct PDFReportService {
    @MainActor
    func exportEstateReport(
        profile: UserProfile?,
        snapshot: EstateReadinessSnapshot,
        assets: [Asset],
        beneficiaries: [Beneficiary],
        digitalAssets: [DigitalAsset],
        documents: [DocumentRecord],
        recordings: [VoiceLegacyRecording]
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyVault-Estate-Review-\(UUID().uuidString).pdf")
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let formatter = AssetAnalysisService()

        try renderer.writePDF(to: url) { context in
            var y: CGFloat = 48
            context.beginPage()

            draw("LegacyVault AI Estate Review", size: 25, weight: .bold, color: UIColor(LegacyTheme.paleGold), y: &y, bounds: pageBounds)
            draw("Protect your family. Preserve your legacy.", size: 13, weight: .medium, color: .white, y: &y, bounds: pageBounds)
            y += 12
            draw("Readiness Score: \(snapshot.score)%", size: 18, weight: .semibold, color: UIColor(LegacyTheme.ivory), y: &y, bounds: pageBounds)
            draw("Total Assets Recorded: \(formatter.formattedCurrency(formatter.totalValue(assets: assets)))", size: 12, weight: .regular, color: .lightGray, y: &y, bounds: pageBounds)
            draw("Profile: \(profile?.maritalStatus ?? "Not completed") | Dependents: \(profile?.dependents ?? 0)", size: 12, weight: .regular, color: .lightGray, y: &y, bounds: pageBounds)
            y += 16

            drawSection("Missing Items", items: snapshot.missingItems, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Recommendations", items: snapshot.improvements, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Assets", items: assets.map { "\($0.title.isEmpty ? $0.assetType : $0.title): \(formatter.formattedCurrency($0.estimatedValue))" }, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Beneficiaries", items: beneficiaries.map { "\($0.name) - \($0.relationship)" }, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Digital Assets", items: digitalAssets.map { "\($0.accountName) - \($0.accountType)" }, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Documents", items: documents.map { "\($0.title) - \($0.reviewStatus)" }, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Voice Legacy", items: recordings.map { "\($0.title): \($0.summary)" }, y: &y, pageBounds: pageBounds, context: context)
            drawSection("Required Legal Disclaimers", items: LegalDisclaimer.bullets, y: &y, pageBounds: pageBounds, context: context)
        }

        return url
    }

    private func drawSection(_ title: String, items: [String], y: inout CGFloat, pageBounds: CGRect, context: UIGraphicsPDFRendererContext) {
        if y > pageBounds.height - 150 {
            context.beginPage()
            y = 48
        }

        draw(title, size: 16, weight: .semibold, color: UIColor(LegacyTheme.paleGold), y: &y, bounds: pageBounds)
        let safeItems = items.isEmpty ? ["No records yet."] : items
        for item in safeItems.prefix(8) {
            draw("- \(item)", size: 11, weight: .regular, color: .white, y: &y, bounds: pageBounds)
        }
        y += 10
    }

    private func draw(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor, y: inout CGFloat, bounds: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let rect = CGRect(x: 48, y: y, width: bounds.width - 96, height: 96)
        text.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        let measured = text.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        y += max(measured.height + 8, size + 10)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
