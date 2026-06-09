import Foundation
import SwiftData

enum LegalLinks {
    static let privacyPolicy = URL(string: "https://github.com/lanray07/LegacyVault-AI/blob/main/privacy-policy.md")!
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

enum LegalDisclaimer {
    static let short = "Educational tool only. Not legal advice. Laws vary by jurisdiction and qualified legal review is recommended."

    static let bullets = [
        "LegacyVault AI is an estate organization and education platform.",
        "It does not provide legal advice or act as a solicitor.",
        "It does not create legally binding documents automatically or guarantee legal validity.",
        "Estate-planning outputs should be reviewed by a qualified professional in the user's jurisdiction."
    ]

    static let pdfText = bullets.joined(separator: "\n")
}

struct EstateReadinessSnapshot: Identifiable, Hashable {
    let id = UUID()
    var score: Int
    var missingItems: [String]
    var improvements: [String]
}

struct EstateMetric: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var value: Double
    var tintName: String
}

@Model
final class UserProfile {
    var maritalStatus: String
    var dependents: Int
    var ownsHome: Bool
    var ownsBusiness: Bool
    var hasDigitalAssets: Bool
    var planningGoals: String
    var createdAt: Date

    init(
        maritalStatus: String = "Not specified",
        dependents: Int = 0,
        ownsHome: Bool = false,
        ownsBusiness: Bool = false,
        hasDigitalAssets: Bool = false,
        planningGoals: String = "",
        createdAt: Date = .now
    ) {
        self.maritalStatus = maritalStatus
        self.dependents = dependents
        self.ownsHome = ownsHome
        self.ownsBusiness = ownsBusiness
        self.hasDigitalAssets = hasDigitalAssets
        self.planningGoals = planningGoals
        self.createdAt = createdAt
    }
}

@Model
final class Asset {
    var title: String
    var assetType: String
    var estimatedValue: Double
    var owner: String
    var notes: String
    var location: String
    var supportingDocuments: String
    var createdAt: Date

    init(
        title: String = "",
        assetType: String = "Property",
        estimatedValue: Double = 0,
        owner: String = "",
        notes: String = "",
        location: String = "",
        supportingDocuments: String = "",
        createdAt: Date = .now
    ) {
        self.title = title
        self.assetType = assetType
        self.estimatedValue = estimatedValue
        self.owner = owner
        self.notes = notes
        self.location = location
        self.supportingDocuments = supportingDocuments
        self.createdAt = createdAt
    }
}

@Model
final class Beneficiary {
    var name: String
    var relationship: String
    var contactInfo: String
    var allocationNote: String
    var notes: String
    var createdAt: Date

    init(
        name: String = "",
        relationship: String = "",
        contactInfo: String = "",
        allocationNote: String = "",
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.relationship = relationship
        self.contactInfo = contactInfo
        self.allocationNote = allocationNote
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class Executor {
    var name: String
    var contactInfo: String
    var responsibilities: String
    var notes: String
    var isPrimary: Bool
    var createdAt: Date

    init(
        name: String = "",
        contactInfo: String = "",
        responsibilities: String = "",
        notes: String = "",
        isPrimary: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.contactInfo = contactInfo
        self.responsibilities = responsibilities
        self.notes = notes
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}

@Model
final class DigitalAsset {
    var accountName: String
    var accountType: String
    var notes: String
    var instructions: String
    var emergencyContact: String
    var createdAt: Date

    init(
        accountName: String = "",
        accountType: String = "Online account",
        notes: String = "",
        instructions: String = "",
        emergencyContact: String = "",
        createdAt: Date = .now
    ) {
        self.accountName = accountName
        self.accountType = accountType
        self.notes = notes
        self.instructions = instructions
        self.emergencyContact = emergencyContact
        self.createdAt = createdAt
    }
}

@Model
final class VoiceLegacyRecording {
    var title: String
    var transcript: String
    var summary: String
    var familyNotes: String
    var executorInstructions: String
    var audioFileName: String
    var durationSeconds: Double
    var createdAt: Date

    init(
        title: String = "",
        transcript: String = "",
        summary: String = "",
        familyNotes: String = "",
        executorInstructions: String = "",
        audioFileName: String = "",
        durationSeconds: Double = 0,
        createdAt: Date = .now
    ) {
        self.title = title
        self.transcript = transcript
        self.summary = summary
        self.familyNotes = familyNotes
        self.executorInstructions = executorInstructions
        self.audioFileName = audioFileName
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
    }
}

@Model
final class EstateReview {
    var readinessScore: Int
    var recommendations: String
    var missingItems: String
    var summary: String
    var estateInsights: String
    var createdAt: Date

    init(
        readinessScore: Int = 0,
        recommendations: String = "",
        missingItems: String = "",
        summary: String = "",
        estateInsights: String = "",
        createdAt: Date = .now
    ) {
        self.readinessScore = readinessScore
        self.recommendations = recommendations
        self.missingItems = missingItems
        self.summary = summary
        self.estateInsights = estateInsights
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    var plan: String
    var isActive: Bool
    var renewalDate: Date?
    var createdAt: Date

    init(plan: String = "Free", isActive: Bool = false, renewalDate: Date? = nil, createdAt: Date = .now) {
        self.plan = plan
        self.isActive = isActive
        self.renewalDate = renewalDate
        self.createdAt = createdAt
    }
}

@Model
final class GuardianPlan {
    var guardianName: String
    var backupGuardianName: String
    var contactInfo: String
    var careInstructions: String
    var educationNotes: String
    var familyWishes: String
    var createdAt: Date

    init(
        guardianName: String = "",
        backupGuardianName: String = "",
        contactInfo: String = "",
        careInstructions: String = "",
        educationNotes: String = "",
        familyWishes: String = "",
        createdAt: Date = .now
    ) {
        self.guardianName = guardianName
        self.backupGuardianName = backupGuardianName
        self.contactInfo = contactInfo
        self.careInstructions = careInstructions
        self.educationNotes = educationNotes
        self.familyWishes = familyWishes
        self.createdAt = createdAt
    }
}

@Model
final class FinalWishesPlan {
    var ceremonyWishes: String
    var dispositionPreference: String
    var charitableDonations: String
    var personalInstructions: String
    var createdAt: Date

    init(
        ceremonyWishes: String = "",
        dispositionPreference: String = "",
        charitableDonations: String = "",
        personalInstructions: String = "",
        createdAt: Date = .now
    ) {
        self.ceremonyWishes = ceremonyWishes
        self.dispositionPreference = dispositionPreference
        self.charitableDonations = charitableDonations
        self.personalInstructions = personalInstructions
        self.createdAt = createdAt
    }
}

@Model
final class LegacyTimelineEvent {
    var title: String
    var eventDate: Date
    var notes: String
    var createdAt: Date

    init(title: String = "", eventDate: Date = .now, notes: String = "", createdAt: Date = .now) {
        self.title = title
        self.eventDate = eventDate
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class FamilyLegacyItem {
    var title: String
    var itemType: String
    var message: String
    var recipient: String
    var deliveryNote: String
    var createdAt: Date

    init(
        title: String = "",
        itemType: String = "Letter",
        message: String = "",
        recipient: String = "",
        deliveryNote: String = "",
        createdAt: Date = .now
    ) {
        self.title = title
        self.itemType = itemType
        self.message = message
        self.recipient = recipient
        self.deliveryNote = deliveryNote
        self.createdAt = createdAt
    }
}

@Model
final class DocumentRecord {
    var title: String
    var documentType: String
    var storageLocation: String
    var reviewStatus: String
    var notes: String
    var isEncryptedPlaceholder: Bool
    var createdAt: Date

    init(
        title: String = "",
        documentType: String = "Will placeholder",
        storageLocation: String = "",
        reviewStatus: String = "Needs review",
        notes: String = "",
        isEncryptedPlaceholder: Bool = true,
        createdAt: Date = .now
    ) {
        self.title = title
        self.documentType = documentType
        self.storageLocation = storageLocation
        self.reviewStatus = reviewStatus
        self.notes = notes
        self.isEncryptedPlaceholder = isEncryptedPlaceholder
        self.createdAt = createdAt
    }
}
