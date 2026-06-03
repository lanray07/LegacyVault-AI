import SwiftData
import SwiftUI

struct DigitalLegacyVaultView: View {
    @EnvironmentObject private var securityViewModel: SecurityViewModel
    @Query(sort: \DigitalAsset.createdAt, order: .reverse) private var digitalAssets: [DigitalAsset]
    @State private var showingAddDigitalAsset = false
    private let secureVaultService = SecureVaultService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VaultCard(
                    title: "Digital Legacy Vault",
                    subtitle: secureVaultService.architectureSummary,
                    symbol: "lock.shield",
                    locked: securityViewModel.biometricsEnabled && securityViewModel.isUnlocked == false
                )

                HStack(spacing: 12) {
                    Button {
                        showingAddDigitalAsset = true
                    } label: {
                        Label("Add Digital Asset", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(PremiumButtonStyle())

                    Button {
                        Task {
                            if securityViewModel.isUnlocked {
                                securityViewModel.lock()
                            } else {
                                await securityViewModel.unlock()
                            }
                        }
                    } label: {
                        Label(securityViewModel.isUnlocked ? "Lock" : "Unlock", systemImage: securityViewModel.isUnlocked ? "lock" : "lock.open")
                    }
                    .buttonStyle(SecondaryPremiumButtonStyle())
                }

                if securityViewModel.isUnlocked {
                    vaultContents
                } else {
                    EmptyStateView(title: "Vault locked", message: "Use biometric authentication to unlock secure estate information.", symbol: "lock.fill")
                }

                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddDigitalAsset) {
            AddDigitalAssetSheet()
        }
    }

    @ViewBuilder
    private var vaultContents: some View {
        if digitalAssets.isEmpty {
            EmptyStateView(title: "No digital assets", message: "Add online accounts, subscriptions, domains, cloud storage, digital businesses, social media, or wallet placeholders.", symbol: "network.badge.shield.half.filled")
        } else {
            ForEach(digitalAssets) { item in
                VaultCard(
                    title: item.accountName.isEmpty ? item.accountType : item.accountName,
                    subtitle: item.instructions.isEmpty ? item.notes : item.instructions,
                    symbol: symbol(for: item.accountType),
                    locked: false
                )
            }
        }
    }

    private func symbol(for type: String) -> String {
        switch type {
        case "Social media": "person.2.wave.2"
        case "Cloud storage": "cloud"
        case "Domain": "globe"
        case "Digital business": "briefcase"
        case "Crypto wallet placeholder": "bitcoinsign.circle"
        case "Subscription": "creditcard"
        default: "key"
        }
    }
}

private struct AddDigitalAssetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var accountName = ""
    @State private var accountType = "Online account"
    @State private var emergencyContact = ""
    @State private var instructions = ""
    @State private var notes = ""

    private let types = [
        "Online account",
        "Subscription",
        "Domain",
        "Social media",
        "Cloud storage",
        "Digital business",
        "Crypto wallet placeholder"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Account name", text: $accountName)
                    Picker("Type", selection: $accountType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Emergency contact", text: $emergencyContact, axis: .vertical)
                }

                Section("Instructions") {
                    TextField("Instructions", text: $instructions, axis: .vertical)
                    TextField("Account notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Add Digital Asset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(DigitalAsset(accountName: accountName, accountType: accountType, notes: notes, instructions: instructions, emergencyContact: emergencyContact))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
