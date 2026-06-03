import Foundation

struct EstateAIRequest: Codable {
    var module: String
    var estateData: [String: String]
    var assetData: [String]
    var voiceTranscript: String
    var beneficiaries: [String]
}

struct EstateAIResponse: Codable {
    var readinessScore: Int
    var recommendations: [String]
    var summary: String
    var estateInsights: [String]
}

struct VoiceSummary: Hashable {
    var summary: String
    var familyNotes: String
    var executorInstructions: String
}

protocol EstateAIProviding {
    func generateEstateReview(request: EstateAIRequest) async throws -> EstateAIResponse
    func summarizeVoiceTranscript(_ transcript: String) async throws -> VoiceSummary
}

enum EstateAIError: LocalizedError {
    case invalidEndpoint
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            "The remote LegacyVault AI endpoint is not configured."
        case .emptyTranscript:
            "Record or enter a transcript before generating a summary."
        }
    }
}

struct MockAIService: EstateAIProviding {
    static let internalPrompt = "You are LegacyVault AI, an estate planning and legacy organization assistant. Help users organize assets, beneficiaries, executors, digital assets, and personal wishes. Provide educational guidance only. Do not provide legal advice, create legally binding documents, or guarantee legal outcomes."

    func generateEstateReview(request: EstateAIRequest) async throws -> EstateAIResponse {
        let baseScore = Int(request.estateData["localReadinessScore"] ?? "38") ?? 38
        let boundedScore = min(96, max(12, baseScore + request.assetData.count * 2 + request.beneficiaries.count * 3))
        let recommendations = [
            "Confirm that all estate documents are reviewed by a qualified professional in the relevant jurisdiction.",
            "Add named beneficiaries and executor contact details for family readiness.",
            "Document digital accounts, subscriptions, cloud storage, and crypto wallet placeholders.",
            "Schedule an annual estate review reminder and keep insurance records in the document vault."
        ]

        return EstateAIResponse(
            readinessScore: boundedScore,
            recommendations: recommendations,
            summary: "Your estate organization profile is developing well. The next best step is to close gaps around documents, executor instructions, and digital asset coverage.",
            estateInsights: [
                "Readiness improves most when beneficiaries, executors, and document locations are clear.",
                "Voice legacy notes can reduce ambiguity for family members while remaining educational and non-binding.",
                LegalDisclaimer.short
            ]
        )
    }

    func summarizeVoiceTranscript(_ transcript: String) async throws -> VoiceSummary {
        let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { throw EstateAIError.emptyTranscript }

        let firstSentence = cleaned
            .split(separator: ".")
            .first
            .map(String.init) ?? cleaned

        return VoiceSummary(
            summary: "This recording captures personal wishes and context for loved ones. Key theme: \(firstSentence).",
            familyNotes: "Preserve the speaker's tone, family priorities, and important relationships when sharing this message.",
            executorInstructions: "Use this as supporting context only. Executor actions should follow legally valid documents and qualified professional guidance."
        )
    }
}

struct RemoteAIService: EstateAIProviding {
    var endpoint: URL?

    init(endpoint: URL? = URL(string: "https://YOUR_BACKEND_URL.com/legacyvault-ai")) {
        self.endpoint = endpoint
    }

    func generateEstateReview(request: EstateAIRequest) async throws -> EstateAIResponse {
        guard let endpoint else { throw EstateAIError.invalidEndpoint }
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try JSONDecoder().decode(EstateAIResponse.self, from: data)
    }

    func summarizeVoiceTranscript(_ transcript: String) async throws -> VoiceSummary {
        let response = try await generateEstateReview(
            request: EstateAIRequest(
                module: "voiceLegacy",
                estateData: ["legalGuardrail": LegalDisclaimer.short],
                assetData: [],
                voiceTranscript: transcript,
                beneficiaries: []
            )
        )

        return VoiceSummary(
            summary: response.summary,
            familyNotes: response.estateInsights.joined(separator: "\n"),
            executorInstructions: response.recommendations.joined(separator: "\n")
        )
    }
}
