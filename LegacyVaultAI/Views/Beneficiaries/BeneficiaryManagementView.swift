import SwiftData
import SwiftUI

struct BeneficiaryManagementView: View {
    @Query(sort: \Beneficiary.createdAt, order: .reverse) private var beneficiaries: [Beneficiary]
    @State private var showingAddBeneficiary = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumCard {
                    SectionHeader(title: "Beneficiary Management", subtitle: "Store family and beneficiary contact details, allocation placeholders, and notes.")
                    Text("Allocation notes are organizational placeholders and do not create legally binding instructions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showingAddBeneficiary = true
                } label: {
                    Label("Add Beneficiary", systemImage: "person.badge.plus")
                }
                .buttonStyle(PremiumButtonStyle())

                if beneficiaries.isEmpty {
                    EmptyStateView(title: "No beneficiaries added", message: "Add people your family and advisers may need to identify.", symbol: "person.2")
                } else {
                    ForEach(beneficiaries) { beneficiary in
                        BeneficiaryCard(beneficiary: beneficiary)
                    }
                }

                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .sheet(isPresented: $showingAddBeneficiary) {
            AddBeneficiarySheet()
        }
    }
}

private struct AddBeneficiarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var relationship = ""
    @State private var contactInfo = ""
    @State private var allocationNote = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Beneficiary") {
                    TextField("Name", text: $name)
                    TextField("Relationship", text: $relationship)
                    TextField("Contact information", text: $contactInfo, axis: .vertical)
                }

                Section("Allocation placeholder") {
                    TextField("Allocation notes", text: $allocationNote, axis: .vertical)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section {
                    Text(LegalDisclaimer.short)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Beneficiary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(Beneficiary(name: name, relationship: relationship, contactInfo: contactInfo, allocationNote: allocationNote, notes: notes))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
