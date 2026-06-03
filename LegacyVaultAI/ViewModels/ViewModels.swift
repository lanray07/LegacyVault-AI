import Combine
import Foundation
import SwiftData

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case protectFamily = "Protect family"
    case organizeAssets = "Organize assets"
    case documentWishes = "Document wishes"
    case prepareExecutor = "Prepare executor"
    case digitalLegacy = "Digital legacy"
    case preserveStories = "Preserve stories"

    var id: String { rawValue }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step = 0
    @Published var maritalStatus = "Married"
    @Published var dependents = 0
    @Published var ownsHome = false
    @Published var ownsBusiness = false
    @Published var hasDigitalAssets = true
    @Published var selectedGoals: Set<OnboardingGoal> = [.protectFamily, .organizeAssets]

    let maritalStatuses = ["Single", "Married", "Civil partnership", "Divorced", "Widowed", "Prefer not to say"]

    var readinessPreview: Int {
        var score = 18
        if ownsHome { score += 8 }
        if ownsBusiness { score += 6 }
        if hasDigitalAssets { score += 6 }
        score += min(18, selectedGoals.count * 3)
        if dependents > 0 { score += 4 }
        return min(score, 58)
    }

    var canAdvance: Bool {
        step < 3
    }

    func toggleGoal(_ goal: OnboardingGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func advance() {
        step = min(step + 1, 3)
    }

    func retreat() {
        step = max(step - 1, 0)
    }

    func createProfile(in context: ModelContext) {
        let profile = UserProfile(
            maritalStatus: maritalStatus,
            dependents: dependents,
            ownsHome: ownsHome,
            ownsBusiness: ownsBusiness,
            hasDigitalAssets: hasDigitalAssets,
            planningGoals: selectedGoals.map(\.rawValue).sorted().joined(separator: ", ")
        )
        let subscription = SubscriptionState(plan: "Free", isActive: false)
        let review = EstateReview(
            readinessScore: readinessPreview,
            recommendations: [
                "Add assets and beneficiaries.",
                "Record executor details.",
                "Store document locations and review status.",
                LegalDisclaimer.short
            ].joined(separator: "\n"),
            missingItems: "Asset inventory, beneficiaries, executor, document vault",
            summary: "Initial onboarding readiness profile created.",
            estateInsights: LegalDisclaimer.short
        )

        context.insert(profile)
        context.insert(subscription)
        context.insert(review)
        try? context.save()
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var snapshot = EstateReadinessSnapshot(score: 0, missingItems: [], improvements: [])
    @Published var roadmap: [String] = []
    @Published var alerts: [String] = []

    private let reviewService = EstateReviewService()
    private let planningService = LegacyPlanningService()
    private let insightService = EstateInsightService()

    func refresh(
        profile: UserProfile?,
        assets: [Asset],
        beneficiaries: [Beneficiary],
        executors: [Executor],
        digitalAssets: [DigitalAsset],
        guardians: [GuardianPlan],
        documents: [DocumentRecord],
        recordings: [VoiceLegacyRecording]
    ) {
        let nextSnapshot = reviewService.calculateReadiness(
            profile: profile,
            assets: assets,
            beneficiaries: beneficiaries,
            executors: executors,
            digitalAssets: digitalAssets,
            guardians: guardians,
            documents: documents,
            recordings: recordings
        )
        snapshot = nextSnapshot
        roadmap = planningService.roadmap(profile: profile, snapshot: nextSnapshot)
        alerts = insightService.alerts(snapshot: nextSnapshot)
    }
}

@MainActor
final class EstateReviewViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var response: EstateAIResponse?

    private let aiService: EstateAIProviding

    init(aiService: EstateAIProviding = MockAIService()) {
        self.aiService = aiService
    }

    func generate(
        snapshot: EstateReadinessSnapshot,
        assets: [Asset],
        beneficiaries: [Beneficiary],
        profile: UserProfile?
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            response = try await aiService.generateEstateReview(
                request: EstateAIRequest(
                    module: "estateReview",
                    estateData: [
                        "maritalStatus": profile?.maritalStatus ?? "Unknown",
                        "dependents": "\(profile?.dependents ?? 0)",
                        "goals": profile?.planningGoals ?? "",
                        "localReadinessScore": "\(snapshot.score)",
                        "legalGuardrail": LegalDisclaimer.short
                    ],
                    assetData: assets.map { "\($0.assetType): \($0.title)" },
                    voiceTranscript: "",
                    beneficiaries: beneficiaries.map(\.name)
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCurrentReview(snapshot: EstateReadinessSnapshot, in context: ModelContext) {
        let review = EstateReview(
            readinessScore: response?.readinessScore ?? snapshot.score,
            recommendations: (response?.recommendations ?? snapshot.improvements).joined(separator: "\n"),
            missingItems: snapshot.missingItems.joined(separator: "\n"),
            summary: response?.summary ?? "Estate review generated from local readiness engine.",
            estateInsights: (response?.estateInsights ?? [LegalDisclaimer.short]).joined(separator: "\n")
        )
        context.insert(review)
        try? context.save()
    }
}

@MainActor
final class VoiceLegacyViewModel: ObservableObject {
    @Published var title = "Personal wishes"
    @Published var transcript = ""
    @Published var summary = ""
    @Published var familyNotes = ""
    @Published var executorInstructions = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    let speechService = SpeechRecognitionService()
    let recordingService = VoiceRecordingService()
    let waveformManager = WaveformAnimationManager()

    private let aiService: EstateAIProviding
    private var cancellables = Set<AnyCancellable>()

    init(aiService: EstateAIProviding = MockAIService()) {
        self.aiService = aiService
        speechService.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.transcript = value
            }
            .store(in: &cancellables)
    }

    func requestSpeechAuthorization() {
        speechService.requestAuthorization()
    }

    func startRecording() {
        do {
            try recordingService.startRecording()
            try speechService.startTranscribing()
            waveformManager.start()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            stopLocalRecording()
        }
    }

    func stopAndSave(in context: ModelContext) async {
        let duration = recordingService.stopRecording()
        speechService.stopTranscribing()
        waveformManager.stop()
        isRecording = false

        do {
            let voiceSummary = try await aiService.summarizeVoiceTranscript(transcript)
            summary = voiceSummary.summary
            familyNotes = voiceSummary.familyNotes
            executorInstructions = voiceSummary.executorInstructions

            let recording = VoiceLegacyRecording(
                title: title.isEmpty ? "Legacy recording" : title,
                transcript: transcript,
                summary: summary,
                familyNotes: familyNotes,
                executorInstructions: executorInstructions,
                audioFileName: recordingService.currentURL?.lastPathComponent ?? "",
                durationSeconds: duration
            )
            context.insert(recording)
            try? context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveEditedTranscript(in context: ModelContext) async {
        do {
            let voiceSummary = try await aiService.summarizeVoiceTranscript(transcript)
            let recording = VoiceLegacyRecording(
                title: title.isEmpty ? "Edited transcript" : title,
                transcript: transcript,
                summary: voiceSummary.summary,
                familyNotes: voiceSummary.familyNotes,
                executorInstructions: voiceSummary.executorInstructions,
                audioFileName: recordingService.currentURL?.lastPathComponent ?? "",
                durationSeconds: recordingService.durationSeconds
            )
            context.insert(recording)
            try? context.save()
            summary = voiceSummary.summary
            familyNotes = voiceSummary.familyNotes
            executorInstructions = voiceSummary.executorInstructions
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopLocalRecording() {
        _ = recordingService.stopRecording()
        speechService.stopTranscribing()
        waveformManager.stop()
        isRecording = false
    }
}
