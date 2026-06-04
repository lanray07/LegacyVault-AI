import SwiftData
import SwiftUI

struct ExecutorDashboardView: View {
    @Query(sort: \Executor.createdAt, order: .reverse) private var executors: [Executor]
    @State private var showingAddExecutor = false

    private let checklist = [
        "Locate professionally reviewed will or trust documents.",
        "Contact qualified legal, tax, and financial professionals.",
        "Secure property, accounts, insurance records, and identity documents.",
        "Review beneficiary information and document locations.",
        "Use LegacyVault AI notes as educational context only."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Executor Dashboard", subtitle: "Store executor details, responsibilities, contact information, and practical instructions.")
                    Text(LegalDisclaimer.short)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingAddExecutor = true
                } label: {
                    Label("Add Executor", systemImage: "person.crop.circle.badge.checkmark")
                }
                .buttonStyle(PremiumButtonStyle())

                if executors.isEmpty {
                    EmptyStateView(title: "No executor recorded", message: "Add the person or professional your family should contact first.", symbol: "person.text.rectangle")
                } else {
                    ForEach(executors) { executor in
                        PremiumCard {
                            Label(executor.name.isEmpty ? "Executor" : executor.name, systemImage: executor.isPrimary ? "star.circle.fill" : "person.circle")
                                .font(.headline)
                                .foregroundStyle(Color.legacyIvory)
                            Text(executor.contactInfo.isEmpty ? "Contact information not added" : executor.contactInfo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if executor.responsibilities.isEmpty == false {
                                Text(executor.responsibilities)
                                    .font(.footnote)
                                    .foregroundStyle(LegacyTheme.paleGold)
                            }
                        }
                    }
                }

                PremiumCard {
                    SectionHeader(title: "Executor Checklist", subtitle: "Educational action plan for estate organization.")
                    ForEach(checklist, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddExecutor) {
            AddExecutorSheet()
        }
    }
}

private struct AddExecutorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var contactInfo = ""
    @State private var responsibilities = ""
    @State private var notes = ""
    @State private var isPrimary = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Executor") {
                    TextField("Name", text: $name)
                    TextField("Contact information", text: $contactInfo, axis: .vertical)
                    Toggle("Primary executor", isOn: $isPrimary)
                }
                Section("Instructions") {
                    TextField("Responsibilities", text: $responsibilities, axis: .vertical)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Add Executor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(Executor(name: name, contactInfo: contactInfo, responsibilities: responsibilities, notes: notes, isPrimary: isPrimary))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GuardianPlanningView: View {
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \GuardianPlan.createdAt, order: .reverse) private var guardians: [GuardianPlan]
    @State private var showingAddGuardian = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Guardian Planning", subtitle: "For families with children or dependents.")
                    if let profile = profiles.first, profile.dependents > 0 {
                        Text("\(profile.dependents) dependent\(profile.dependents == 1 ? "" : "s") recorded in your legacy profile.")
                            .font(.subheadline)
                            .foregroundStyle(LegacyTheme.paleGold)
                    }
                    Text(LegalDisclaimer.short)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingAddGuardian = true
                } label: {
                    Label("Add Guardian Plan", systemImage: "figure.and.child.holdinghands")
                }
                .buttonStyle(PremiumButtonStyle())

                if guardians.isEmpty {
                    EmptyStateView(title: "No guardian plan", message: "Record guardian and backup guardian preferences, care instructions, education notes, and family wishes.", symbol: "figure.2.and.child.holdinghands")
                } else {
                    ForEach(guardians) { guardian in
                        PremiumCard {
                            Label(guardian.guardianName.isEmpty ? "Guardian preference" : guardian.guardianName, systemImage: "heart.text.square")
                                .font(.headline)
                                .foregroundStyle(Color.legacyIvory)
                            Text("Backup: \(guardian.backupGuardianName.isEmpty ? "Not added" : guardian.backupGuardianName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if guardian.careInstructions.isEmpty == false {
                                Text(guardian.careInstructions)
                                    .font(.footnote)
                                    .foregroundStyle(LegacyTheme.paleGold)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddGuardian) {
            AddGuardianPlanSheet()
        }
    }
}

private struct AddGuardianPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var guardianName = ""
    @State private var backupGuardianName = ""
    @State private var contactInfo = ""
    @State private var careInstructions = ""
    @State private var educationNotes = ""
    @State private var familyWishes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Guardians") {
                    TextField("Guardian", text: $guardianName)
                    TextField("Backup guardian", text: $backupGuardianName)
                    TextField("Contact information", text: $contactInfo, axis: .vertical)
                }
                Section("Care wishes") {
                    TextField("Care instructions", text: $careInstructions, axis: .vertical)
                    TextField("Education notes", text: $educationNotes, axis: .vertical)
                    TextField("Family wishes", text: $familyWishes, axis: .vertical)
                }
            }
            .navigationTitle("Guardian Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(GuardianPlan(guardianName: guardianName, backupGuardianName: backupGuardianName, contactInfo: contactInfo, careInstructions: careInstructions, educationNotes: educationNotes, familyWishes: familyWishes))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FinalWishesPlannerView: View {
    @Query(sort: \FinalWishesPlan.createdAt, order: .reverse) private var wishes: [FinalWishesPlan]
    @State private var showingAddWishes = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Funeral & Final Wishes", subtitle: "Record ceremony preferences, burial or cremation preferences, charitable donations, and personal instructions.")
                    Text(LegalDisclaimer.short)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingAddWishes = true
                } label: {
                    Label("Add Final Wishes", systemImage: "text.book.closed")
                }
                .buttonStyle(PremiumButtonStyle())

                if wishes.isEmpty {
                    EmptyStateView(title: "No final wishes recorded", message: "Add personal preferences so family members have calm, practical guidance.", symbol: "leaf")
                } else {
                    ForEach(wishes) { wish in
                        EstateReviewCard(title: wish.dispositionPreference.isEmpty ? "Final wishes" : wish.dispositionPreference, summary: wish.personalInstructions.isEmpty ? wish.ceremonyWishes : wish.personalInstructions, score: nil)
                    }
                }
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddWishes) {
            AddFinalWishesSheet()
        }
    }
}

private struct AddFinalWishesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var ceremonyWishes = ""
    @State private var dispositionPreference = "Not specified"
    @State private var charitableDonations = ""
    @State private var personalInstructions = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Preference", selection: $dispositionPreference) {
                    Text("Not specified").tag("Not specified")
                    Text("Burial").tag("Burial")
                    Text("Cremation").tag("Cremation")
                    Text("Other").tag("Other")
                }
                TextField("Ceremony wishes", text: $ceremonyWishes, axis: .vertical)
                TextField("Charitable donations", text: $charitableDonations, axis: .vertical)
                TextField("Personal instructions", text: $personalInstructions, axis: .vertical)
            }
            .navigationTitle("Final Wishes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(FinalWishesPlan(ceremonyWishes: ceremonyWishes, dispositionPreference: dispositionPreference, charitableDonations: charitableDonations, personalInstructions: personalInstructions))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AIEstateAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = EstateReviewViewModel()
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \Asset.createdAt, order: .reverse) private var assets: [Asset]
    @Query(sort: \Beneficiary.createdAt, order: .reverse) private var beneficiaries: [Beneficiary]
    @Query(sort: \Executor.createdAt, order: .reverse) private var executors: [Executor]
    @Query(sort: \DigitalAsset.createdAt, order: .reverse) private var digitalAssets: [DigitalAsset]
    @Query(sort: \GuardianPlan.createdAt, order: .reverse) private var guardians: [GuardianPlan]
    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]
    @Query(sort: \VoiceLegacyRecording.createdAt, order: .reverse) private var recordings: [VoiceLegacyRecording]

    private let reviewService = EstateReviewService()

    private var snapshot: EstateReadinessSnapshot {
        reviewService.calculateReadiness(
            profile: profiles.first,
            assets: assets,
            beneficiaries: beneficiaries,
            executors: executors,
            digitalAssets: digitalAssets,
            guardians: guardians,
            documents: documents,
            recordings: recordings
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "AI Estate Assistant", subtitle: "Mock AI generates estate organization recommendations, missing document alerts, planning suggestions, and annual review reminders.")
                    Text("The assistant is constrained to educational guidance and always recommends qualified professional review.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        await viewModel.generate(snapshot: snapshot, assets: assets, beneficiaries: beneficiaries, profile: profiles.first)
                        viewModel.saveCurrentReview(snapshot: snapshot, in: modelContext)
                    }
                } label: {
                    Label("Generate Estate Insights", systemImage: "sparkles")
                }
                .buttonStyle(PremiumButtonStyle())

                if viewModel.isLoading {
                    LoadingStateView(message: "Generating educational recommendations...")
                }

                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error)
                }

                if let response = viewModel.response {
                    EstateReviewCard(title: "Estate Organization Summary", summary: response.summary, score: response.readinessScore)
                    PremiumCard {
                        SectionHeader(title: "Recommendations", subtitle: nil)
                        ForEach(response.recommendations, id: \.self) { recommendation in
                            Label(recommendation, systemImage: "lightbulb")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    PremiumCard {
                        SectionHeader(title: "Estate Insights", subtitle: nil)
                        ForEach(response.estateInsights, id: \.self) { insight in
                            Label(insight, systemImage: "checkmark.shield")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                LegalDisclaimerBanner()
            }
            .padding(18)
        }
        .premiumScreenBackground()
    }
}

struct LegacyTimelineView: View {
    @Query(sort: \LegacyTimelineEvent.eventDate, order: .reverse) private var events: [LegacyTimelineEvent]
    @State private var showingAddEvent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Legacy Timeline", subtitle: "Major life events, family milestones, personal stories, and legacy notes.")
                }

                Button {
                    showingAddEvent = true
                } label: {
                    Label("Add Timeline Event", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(PremiumButtonStyle())

                if events.isEmpty {
                    EmptyStateView(title: "No timeline events", message: "Capture milestones and stories that give context to your legacy plan.", symbol: "timeline.selection")
                } else {
                    ForEach(events) { event in
                        PremiumCard {
                            Text(event.title.isEmpty ? "Life event" : event.title)
                                .font(.headline)
                                .foregroundStyle(Color.legacyIvory)
                            Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(LegacyTheme.paleGold)
                            Text(event.notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddEvent) {
            AddTimelineEventSheet()
        }
    }
}

private struct AddTimelineEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var eventDate = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Timeline Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(LegacyTimelineEvent(title: title, eventDate: eventDate, notes: notes))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FamilyLegacyVaultView: View {
    @Query(sort: \FamilyLegacyItem.createdAt, order: .reverse) private var items: [FamilyLegacyItem]
    @State private var showingAddItem = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Family Legacy Vault", subtitle: "Family history, letters, photo placeholders, audio messages, and future messages.")
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title)
                            .foregroundStyle(LegacyTheme.gold)
                        Text("Human asset placeholders are ready for family photography, letters, and audio memories.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Legacy Item", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PremiumButtonStyle())

                if items.isEmpty {
                    EmptyStateView(title: "No family legacy items", message: "Add stories, letters, photos, audio messages, and future notes for loved ones.", symbol: "heart.text.square")
                } else {
                    ForEach(items) { item in
                        VaultCard(title: item.title.isEmpty ? item.itemType : item.title, subtitle: item.message.isEmpty ? item.deliveryNote : item.message, symbol: symbol(for: item.itemType), locked: false)
                    }
                }
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddItem) {
            AddFamilyLegacyItemSheet()
        }
    }

    private func symbol(for type: String) -> String {
        switch type {
        case "Photo placeholder": "photo"
        case "Audio message": "waveform"
        case "Future message": "clock.badge"
        default: "envelope"
        }
    }
}

private struct AddFamilyLegacyItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var itemType = "Letter"
    @State private var message = ""
    @State private var recipient = ""
    @State private var deliveryNote = ""

    private let types = ["Letter", "Photo placeholder", "Audio message", "Future message", "Family history"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Type", selection: $itemType) {
                    ForEach(types, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                TextField("Recipient", text: $recipient)
                TextField("Message", text: $message, axis: .vertical)
                TextField("Delivery note", text: $deliveryNote, axis: .vertical)
            }
            .navigationTitle("Legacy Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(FamilyLegacyItem(title: title, itemType: itemType, message: message, recipient: recipient, deliveryNote: deliveryNote))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentVaultView: View {
    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]
    @State private var showingAddDocument = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VaultCard(title: "Secure Document Vault", subtitle: "Architecture for wills, trusts, insurance, property, identification, and legal record storage.", symbol: "doc.badge.gearshape", locked: true)

                Button {
                    showingAddDocument = true
                } label: {
                    Label("Add Document Record", systemImage: "doc.badge.plus")
                }
                .buttonStyle(PremiumButtonStyle())

                if documents.isEmpty {
                    EmptyStateView(title: "No document records", message: "Store document locations and review status. This does not create legal documents or guarantee validity.", symbol: "doc.text.magnifyingglass")
                } else {
                    ForEach(documents) { document in
                        VaultCard(title: document.title.isEmpty ? document.documentType : document.title, subtitle: "\(document.reviewStatus) | \(document.storageLocation)", symbol: "doc.text", locked: document.isEncryptedPlaceholder)
                    }
                }

                LegalDisclaimerBanner()
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddDocument) {
            AddDocumentRecordSheet()
        }
    }
}

private struct AddDocumentRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var documentType = "Will placeholder"
    @State private var storageLocation = ""
    @State private var reviewStatus = "Needs professional review"
    @State private var notes = ""
    @State private var isEncryptedPlaceholder = true

    private let types = [
        "Will placeholder",
        "Trust placeholder",
        "Insurance document",
        "Property document",
        "Identification",
        "Legal record",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Type", selection: $documentType) {
                    ForEach(types, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                TextField("Storage location", text: $storageLocation, axis: .vertical)
                TextField("Review status", text: $reviewStatus)
                Toggle("Encrypted storage placeholder", isOn: $isEncryptedPlaceholder)
                TextField("Notes", text: $notes, axis: .vertical)
                Text(LegalDisclaimer.short)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Document Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(DocumentRecord(title: title, documentType: documentType, storageLocation: storageLocation, reviewStatus: reviewStatus, notes: notes, isEncryptedPlaceholder: isEncryptedPlaceholder))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EstateReviewReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \Asset.createdAt, order: .reverse) private var assets: [Asset]
    @Query(sort: \Beneficiary.createdAt, order: .reverse) private var beneficiaries: [Beneficiary]
    @Query(sort: \Executor.createdAt, order: .reverse) private var executors: [Executor]
    @Query(sort: \DigitalAsset.createdAt, order: .reverse) private var digitalAssets: [DigitalAsset]
    @Query(sort: \GuardianPlan.createdAt, order: .reverse) private var guardians: [GuardianPlan]
    @Query(sort: \DocumentRecord.createdAt, order: .reverse) private var documents: [DocumentRecord]
    @Query(sort: \VoiceLegacyRecording.createdAt, order: .reverse) private var recordings: [VoiceLegacyRecording]
    @Query(sort: \EstateReview.createdAt, order: .reverse) private var reviews: [EstateReview]

    @State private var shareItem: ReportShareItem?
    @State private var errorMessage: String?

    private let reviewService = EstateReviewService()
    private let pdfService = PDFReportService()

    private var snapshot: EstateReadinessSnapshot {
        reviewService.calculateReadiness(
            profile: profiles.first,
            assets: assets,
            beneficiaries: beneficiaries,
            executors: executors,
            digitalAssets: digitalAssets,
            guardians: guardians,
            documents: documents,
            recordings: recordings
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ReportPreviewView(snapshot: snapshot, assetsCount: assets.count, beneficiariesCount: beneficiaries.count, documentsCount: documents.count)

                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF Report", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PremiumButtonStyle())

                if let errorMessage {
                    ErrorStateView(message: errorMessage)
                }

                SectionHeader(title: "Review History", subtitle: "Saved readiness reports and AI estate reviews.")
                if reviews.isEmpty {
                    EmptyStateView(title: "No review history", message: "Generate a report to save an estate readiness snapshot.", symbol: "doc.richtext")
                } else {
                    ForEach(reviews) { review in
                        EstateReviewCard(title: review.createdAt.formatted(date: .abbreviated, time: .shortened), summary: review.summary, score: review.readinessScore)
                    }
                }

                LegalDisclaimerBanner()
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private func exportPDF() {
        do {
            let url = try pdfService.exportEstateReport(
                profile: profiles.first,
                snapshot: snapshot,
                assets: assets,
                beneficiaries: beneficiaries,
                digitalAssets: digitalAssets,
                documents: documents,
                recordings: recordings
            )
            let review = EstateReview(
                readinessScore: snapshot.score,
                recommendations: snapshot.improvements.joined(separator: "\n"),
                missingItems: snapshot.missingItems.joined(separator: "\n"),
                summary: "PDF estate review report exported.",
                estateInsights: LegalDisclaimer.short
            )
            modelContext.insert(review)
            try? modelContext.save()
            shareItem = ReportShareItem(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ReportShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
