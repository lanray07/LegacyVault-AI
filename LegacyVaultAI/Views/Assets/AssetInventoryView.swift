import SwiftData
import SwiftUI

struct AssetInventoryView: View {
    @Query(sort: \Asset.createdAt, order: .reverse) private var assets: [Asset]
    @State private var showingAddAsset = false
    private let assetService = AssetAnalysisService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Asset Inventory", subtitle: "Property, bank accounts, investments, pensions, vehicles, businesses, collectibles, crypto placeholders, and other assets.")
                    HStack {
                        Label("\(assets.count) records", systemImage: "archivebox")
                        Spacer()
                        Text(assetService.formattedCurrency(assetService.totalValue(assets: assets)))
                            .font(.headline)
                            .foregroundStyle(LegacyTheme.paleGold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Button {
                    showingAddAsset = true
                } label: {
                    Label("Add Asset", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PremiumButtonStyle())

                if assets.isEmpty {
                    EmptyStateView(title: "No assets recorded", message: "Start with the assets your family would need to locate quickly.", symbol: "building.columns")
                } else {
                    ForEach(assets) { asset in
                        AssetCard(asset: asset)
                    }
                }

                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddAsset) {
            AddAssetSheet()
        }
    }
}

private struct AddAssetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var assetType = "Property"
    @State private var estimatedValue = ""
    @State private var owner = ""
    @State private var location = ""
    @State private var supportingDocuments = ""
    @State private var notes = ""

    private let assetTypes = [
        "Property",
        "Bank account",
        "Investment",
        "Pension",
        "Vehicle",
        "Business",
        "Collectible",
        "Crypto placeholder",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Name", text: $title)
                    Picker("Type", selection: $assetType) {
                        ForEach(assetTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Estimated value", text: $estimatedValue)
                        .keyboardType(.decimalPad)
                    TextField("Owner", text: $owner)
                }

                Section("Location and documents") {
                    TextField("Location", text: $location)
                    TextField("Supporting documents", text: $supportingDocuments, axis: .vertical)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section {
                    Text(LegalDisclaimer.short)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Asset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let value = Double(estimatedValue.replacingOccurrences(of: ",", with: "")) ?? 0
        let asset = Asset(
            title: title,
            assetType: assetType,
            estimatedValue: value,
            owner: owner,
            notes: notes,
            location: location,
            supportingDocuments: supportingDocuments
        )
        modelContext.insert(asset)
        try? modelContext.save()
        dismiss()
    }
}
