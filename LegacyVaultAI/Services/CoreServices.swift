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
    @Published var statusMessage: String?

    private let productIDs = [
        premiumMonthlyID,
        premiumYearlyID,
        familyOfficeMonthlyID
    ]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            loadingError = nil
        } catch {
            loadingError = "Unable to load subscription products. Please check your connection and try again."
        }
    }

    func purchase(_ product: Product) async throws {
        loadingError = nil
        statusMessage = "Opening App Store purchase sheet..."
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                displayState = DisplayState(plan: planName(for: transaction.productID), isActive: true)
                statusMessage = "\(displayState.plan) subscription active."
            } else {
                loadingError = "The purchase could not be verified. Please try again."
                statusMessage = nil
            }
        case .pending:
            statusMessage = "Purchase is pending approval."
        case .userCancelled:
            statusMessage = "Purchase cancelled."
        @unknown default:
            loadingError = "The purchase could not be completed. Please try again."
            statusMessage = nil
        }
    }

    func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                displayState = DisplayState(plan: planName(for: transaction.productID), isActive: true)
                return
            }
        }
        if displayState.isActive == false {
            displayState = DisplayState(plan: "Free", isActive: false)
        }
    }

    func restorePurchases() async {
        loadingError = nil
        statusMessage = "Checking previous purchases..."
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = displayState.isActive ? "\(displayState.plan) restored." : "No active purchases found."
        } catch {
            loadingError = "Unable to restore purchases. Please try again."
            statusMessage = nil
        }
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

@MainActor
enum DemoDataSeeder {
    static let isEnabled = true

    static func seedIfNeeded(existingProfiles: [UserProfile], in context: ModelContext) -> String? {
        guard isEnabled, existingProfiles.isEmpty else { return nil }

        let profile = UserProfile(
            maritalStatus: "Married",
            dependents: 2,
            ownsHome: true,
            ownsBusiness: true,
            hasDigitalAssets: true,
            planningGoals: "Protect family, Organize assets, Prepare executor, Digital legacy, Preserve stories"
        )

        let assets = [
            Asset(
                title: "Harper family home",
                assetType: "Property",
                estimatedValue: 875_000,
                owner: "Olivia and James Harper",
                notes: "Mortgage documents and title reference are stored with the solicitor. Annual insurance review due each September.",
                location: "Richmond, London",
                supportingDocuments: "Property deed, mortgage statement, buildings insurance"
            ),
            Asset(
                title: "Family emergency fund",
                assetType: "Bank account",
                estimatedValue: 64_500,
                owner: "Olivia Harper",
                notes: "Executor should contact the private banking relationship manager listed in the document vault.",
                location: "Secure banking portal",
                supportingDocuments: "Latest bank statement"
            ),
            Asset(
                title: "Harper & Co. design studio",
                assetType: "Business",
                estimatedValue: 245_000,
                owner: "James Harper",
                notes: "Succession note: Maya Grant can operate payroll and client handover in an emergency.",
                location: "Companies House and studio safe",
                supportingDocuments: "Share certificate, accountant contact, insurance"
            ),
            Asset(
                title: "Long-term investment portfolio",
                assetType: "Investment",
                estimatedValue: 318_400,
                owner: "Joint",
                notes: "Allocation reviewed with adviser each January. Beneficiary notes are organizational only.",
                location: "Wealth platform",
                supportingDocuments: "Portfolio statement"
            ),
            Asset(
                title: "Pension plans",
                assetType: "Pension",
                estimatedValue: 402_000,
                owner: "Olivia and James Harper",
                notes: "Nomination forms need professional review after any major family change.",
                location: "Provider portals",
                supportingDocuments: "Pension summaries"
            ),
            Asset(
                title: "Digital wallet placeholder",
                assetType: "Crypto placeholder",
                estimatedValue: 12_500,
                owner: "James Harper",
                notes: "Recovery phrase location is not stored in plain text. Executor should contact appointed adviser.",
                location: "Secure offline storage",
                supportingDocuments: "Wallet inventory note"
            )
        ]

        let beneficiaries = [
            Beneficiary(
                name: "Sofia Harper",
                relationship: "Daughter",
                contactInfo: "Care of Olivia and James Harper",
                allocationNote: "Education and long-term care priority placeholder",
                notes: "Guardian plan includes school continuity and family travel preferences."
            ),
            Beneficiary(
                name: "Leo Harper",
                relationship: "Son",
                contactInfo: "Care of Olivia and James Harper",
                allocationNote: "Education and wellbeing priority placeholder",
                notes: "Include notes about therapy provider, routines, and grandparents."
            ),
            Beneficiary(
                name: "Amara Reed",
                relationship: "Sister",
                contactInfo: "amara.reed@example.com | +44 7700 900123",
                allocationNote: "Sentimental items and family archive custodian placeholder",
                notes: "Trusted family contact for letters, photos, and personal messages."
            )
        ]

        let executors = [
            Executor(
                name: "Amara Reed",
                contactInfo: "amara.reed@example.com | +44 7700 900123",
                responsibilities: "Contact solicitor, secure home documents, support children's guardians, and coordinate family communications.",
                notes: "Primary family executor. Confirm legal appointment with solicitor.",
                isPrimary: true
            ),
            Executor(
                name: "Maya Grant",
                contactInfo: "maya.grant@example.com | +44 7700 900456",
                responsibilities: "Business continuity, payroll, vendor handover, and accountant coordination.",
                notes: "Business continuity contact, not a substitute for legal advice.",
                isPrimary: false
            )
        ]

        let digitalAssets = [
            DigitalAsset(
                accountName: "Primary email and cloud drive",
                accountType: "Cloud storage",
                notes: "Contains family photo archive, scanned insurance records, and household manuals.",
                instructions: "Emergency access should follow provider policy and solicitor guidance.",
                emergencyContact: "Amara Reed"
            ),
            DigitalAsset(
                accountName: "Family subscription hub",
                accountType: "Subscription",
                notes: "Music, streaming, children's apps, password manager family plan.",
                instructions: "Cancel non-essential subscriptions after household review.",
                emergencyContact: "James Harper's accountant"
            ),
            DigitalAsset(
                accountName: "harperandco.studio",
                accountType: "Domain",
                notes: "Business domain and client landing pages.",
                instructions: "Renew domain for at least 24 months during business transition.",
                emergencyContact: "Maya Grant"
            ),
            DigitalAsset(
                accountName: "Design studio social accounts",
                accountType: "Social media",
                notes: "Instagram, LinkedIn, and portfolio channels.",
                instructions: "Pause scheduled posts and publish continuity notice only after adviser review.",
                emergencyContact: "Maya Grant"
            ),
            DigitalAsset(
                accountName: "Cold storage inventory",
                accountType: "Crypto wallet placeholder",
                notes: "No seed phrase stored in the app. Location instructions are held offline.",
                instructions: "Executor should not attempt transfers without qualified specialist support.",
                emergencyContact: "Private wealth adviser"
            )
        ]

        let guardianPlans = [
            GuardianPlan(
                guardianName: "Amara Reed",
                backupGuardianName: "Nadia Cole",
                contactInfo: "Amara Reed, amara.reed@example.com",
                careInstructions: "Keep Sofia and Leo together, maintain school continuity, and preserve weekly calls with grandparents.",
                educationNotes: "Both children thrive with music, outdoor time, and predictable routines.",
                familyWishes: "Prioritize emotional stability, sibling connection, and access to family history."
            )
        ]

        let finalWishes = [
            FinalWishesPlan(
                ceremonyWishes: "Small ceremony with close family, acoustic music, and letters read privately.",
                dispositionPreference: "Cremation",
                charitableDonations: "Family may support children's literacy and mental health charities.",
                personalInstructions: "Keep the tone warm, simple, and family-centered. No expensive formalities are expected."
            )
        ]

        let timelineEvents = [
            LegacyTimelineEvent(
                title: "Olivia and James wedding",
                eventDate: Calendar.current.date(from: DateComponents(year: 2014, month: 6, day: 21)) ?? .now,
                notes: "A summer garden ceremony that became the family story everyone still tells."
            ),
            LegacyTimelineEvent(
                title: "Sofia was born",
                eventDate: Calendar.current.date(from: DateComponents(year: 2017, month: 9, day: 12)) ?? .now,
                notes: "The moment the family's priorities changed from ambition to protection."
            ),
            LegacyTimelineEvent(
                title: "Harper & Co. launched",
                eventDate: Calendar.current.date(from: DateComponents(year: 2020, month: 2, day: 3)) ?? .now,
                notes: "Started from the kitchen table and became a studio with seven clients in year one."
            )
        ]

        let familyLegacyItems = [
            FamilyLegacyItem(
                title: "Letter for Sofia at 18",
                itemType: "Future message",
                message: "A note about courage, kindness, and choosing friends who make life feel lighter.",
                recipient: "Sofia Harper",
                deliveryNote: "Share on Sofia's eighteenth birthday."
            ),
            FamilyLegacyItem(
                title: "Grandparents' recipes",
                itemType: "Family history",
                message: "Sunday sauce, lemon cake, and the handwritten notes from Nana Reed.",
                recipient: "Sofia and Leo Harper",
                deliveryNote: "Keep with the family photo archive."
            ),
            FamilyLegacyItem(
                title: "Audio message for Leo",
                itemType: "Audio message",
                message: "A short message about curiosity, football Saturdays, and being gentle with himself.",
                recipient: "Leo Harper",
                deliveryNote: "Share when he asks about family memories."
            )
        ]

        let documents = [
            DocumentRecord(
                title: "Will location note",
                documentType: "Will placeholder",
                storageLocation: "Solicitor vault and home fire safe",
                reviewStatus: "Needs qualified legal review after 2026 updates",
                notes: "LegacyVault AI does not create or validate this document.",
                isEncryptedPlaceholder: true
            ),
            DocumentRecord(
                title: "Life insurance policy",
                documentType: "Insurance document",
                storageLocation: "Document vault and provider portal",
                reviewStatus: "Reviewed January 2026",
                notes: "Check beneficiary nomination annually.",
                isEncryptedPlaceholder: true
            ),
            DocumentRecord(
                title: "Property deed reference",
                documentType: "Property document",
                storageLocation: "Solicitor file reference HV-2214",
                reviewStatus: "Location verified",
                notes: "Executor should request certified copies if needed.",
                isEncryptedPlaceholder: true
            ),
            DocumentRecord(
                title: "Passports and IDs",
                documentType: "Identification",
                storageLocation: "Home fire safe",
                reviewStatus: "Current",
                notes: "Copies are for organization only.",
                isEncryptedPlaceholder: true
            )
        ]

        let recordings = [
            VoiceLegacyRecording(
                title: "Personal wishes for the children",
                transcript: "If something happened tomorrow, I want Sofia and Leo to know they were loved beyond measure. Keep them together, keep routines steady, and let them hear our stories often.",
                summary: "A warm message centered on stability, sibling connection, and preserving family stories.",
                familyNotes: "Share with Amara and the children when the family needs emotional context.",
                executorInstructions: "Use as personal context only. Formal decisions should follow valid documents and qualified professional guidance.",
                audioFileName: "legacy-voice-demo-children.m4a",
                durationSeconds: 84
            ),
            VoiceLegacyRecording(
                title: "Executor business context",
                transcript: "Maya knows the studio operations best. The priority is paying staff, pausing new work, and communicating clearly with clients.",
                summary: "Business continuity guidance for the design studio.",
                familyNotes: "Preserve the business only if it supports the family's wellbeing.",
                executorInstructions: "Contact Maya and the accountant before making business decisions.",
                audioFileName: "legacy-voice-demo-business.m4a",
                durationSeconds: 52
            )
        ]

        let review = EstateReview(
            readinessScore: 88,
            recommendations: [
                "Schedule a qualified legal review for the will and guardian preferences.",
                "Add updated pension nomination confirmation.",
                "Review digital access instructions annually.",
                LegalDisclaimer.short
            ].joined(separator: "\n"),
            missingItems: "Professional legal review date, updated pension nomination confirmation",
            summary: "The Harper family profile is substantially organized with strong beneficiary, document, executor, and digital legacy coverage.",
            estateInsights: "Family Office demo profile. Educational organization only. Jurisdiction-specific professional advice remains required."
        )

        let subscription = SubscriptionState(
            plan: "Family Office",
            isActive: true,
            renewalDate: Calendar.current.date(byAdding: .month, value: 1, to: .now)
        )

        context.insert(profile)
        context.insert(subscription)
        assets.forEach { context.insert($0) }
        beneficiaries.forEach { context.insert($0) }
        executors.forEach { context.insert($0) }
        digitalAssets.forEach { context.insert($0) }
        guardianPlans.forEach { context.insert($0) }
        finalWishes.forEach { context.insert($0) }
        timelineEvents.forEach { context.insert($0) }
        familyLegacyItems.forEach { context.insert($0) }
        documents.forEach { context.insert($0) }
        recordings.forEach { context.insert($0) }
        context.insert(review)

        try? context.save()
        return subscription.plan
    }
}
