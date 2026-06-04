import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    progress
                    currentStep
                    LegalDisclaimerBanner(compact: viewModel.step != 0)
                    controls
                }
                .padding(20)
            }
            .premiumScreenBackground()
            .navigationTitle("LegacyVault AI")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Color.legacyGold)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protect your family. Preserve your legacy.")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Color.legacyIvory)
                .fixedSize(horizontal: false, vertical: true)
            Text("If something happened tomorrow, would your family know what to do?")
                .font(.title3.weight(.medium))
                .foregroundStyle(LegacyTheme.paleGold)
                .fixedSize(horizontal: false, vertical: true)
            PremiumCard {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.title)
                        .foregroundStyle(LegacyTheme.gold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Private family office planning")
                            .font(.headline)
                            .foregroundStyle(Color.legacyIvory)
                        Text("Organize wishes, people, documents, and assets in one secure estate profile.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(viewModel.step + 1) of 4")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.readinessPreview)% preview")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LegacyTheme.paleGold)
            }
            ProgressView(value: Double(viewModel.step + 1), total: 4)
                .tint(LegacyTheme.gold)
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch viewModel.step {
        case 0:
            PremiumCard {
                SectionHeader(title: "Estate education guardrails", subtitle: "LegacyVault AI helps organize information. It does not replace professional advice.")
                Text("Every estate-planning output includes a lawyer review recommendation, jurisdiction disclaimer, and legal validity warning.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case 1:
            PremiumCard {
                SectionHeader(title: "Household", subtitle: "Build your legacy profile.")
                Picker("Marital status", selection: $viewModel.maritalStatus) {
                    ForEach(viewModel.maritalStatuses, id: \.self) { status in
                        Text(status).tag(status)
                    }
                }
                .pickerStyle(.menu)
                Stepper("Children or dependents: \(viewModel.dependents)", value: $viewModel.dependents, in: 0...12)
            }
        case 2:
            PremiumCard {
                SectionHeader(title: "Ownership", subtitle: "Help the readiness engine identify planning areas.")
                Toggle("Home ownership", isOn: $viewModel.ownsHome)
                Toggle("Business ownership", isOn: $viewModel.ownsBusiness)
                Toggle("Digital assets", isOn: $viewModel.hasDigitalAssets)
            }
        default:
            PremiumCard {
                SectionHeader(title: "Planning goals", subtitle: "Choose the outcomes you want LegacyVault AI to prioritize.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(OnboardingGoal.allCases) { goal in
                        Button {
                            viewModel.toggleGoal(goal)
                        } label: {
                            HStack {
                                Image(systemName: viewModel.selectedGoals.contains(goal) ? "checkmark.circle.fill" : "circle")
                                Text(goal.rawValue)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                Spacer()
                            }
                            .font(.subheadline.weight(.medium))
                            .padding(12)
                            .frame(minHeight: 52)
                            .background(
                                viewModel.selectedGoals.contains(goal) ? LegacyTheme.gold.opacity(0.18) : LegacyTheme.charcoal.opacity(0.45),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(viewModel.selectedGoals.contains(goal) ? LegacyTheme.paleGold : .secondary)
                    }
                }
                ReadinessScoreRing(score: viewModel.readinessPreview, label: "Profile Preview")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if viewModel.step > 0 {
                Button {
                    viewModel.retreat()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(SecondaryPremiumButtonStyle())
            }

            Button {
                if viewModel.canAdvance {
                    viewModel.advance()
                } else {
                    viewModel.createProfile(in: modelContext)
                }
            } label: {
                Label(viewModel.canAdvance ? "Continue" : "Create Legacy Profile", systemImage: viewModel.canAdvance ? "chevron.right" : "checkmark.shield")
            }
            .buttonStyle(PremiumButtonStyle())
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, EstateReview.self, SubscriptionState.self], inMemory: true)
}
