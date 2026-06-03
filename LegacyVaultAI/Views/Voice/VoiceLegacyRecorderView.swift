import SwiftData
import SwiftUI

struct VoiceLegacyRecorderView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = VoiceLegacyViewModel()
    @Query(sort: \VoiceLegacyRecording.createdAt, order: .reverse) private var recordings: [VoiceLegacyRecording]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                recorder
                transcriptEditor
                generatedNotes
                previousRecordings
                LegalDisclaimerBanner(compact: true)
            }
            .padding(18)
        }
        .premiumScreenBackground()
        .task {
            viewModel.requestSpeechAuthorization()
        }
    }

    private var recorder: some View {
        PremiumCard {
            SectionHeader(title: "Voice Legacy Recorder", subtitle: "Record wishes, family messages, asset intentions, and executor context.")
            TextField("Recording title", text: $viewModel.title)
                .textFieldStyle(.roundedBorder)
            VoiceWaveformView(levels: viewModel.waveformManager.levels, isRecording: viewModel.isRecording)
            HStack(spacing: 12) {
                Button {
                    if viewModel.isRecording {
                        Task { await viewModel.stopAndSave(in: modelContext) }
                    } else {
                        viewModel.startRecording()
                    }
                } label: {
                    Label(viewModel.isRecording ? "Stop and Save" : "Start Recording", systemImage: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                }
                .buttonStyle(PremiumButtonStyle())

                Button {
                    Task { await viewModel.saveEditedTranscript(in: modelContext) }
                } label: {
                    Label("Save Transcript", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(SecondaryPremiumButtonStyle())
                .disabled(viewModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            VaultCard(
                title: "Encrypted storage placeholder",
                subtitle: "Audio metadata and transcript records are staged for secure vault storage architecture.",
                symbol: "lock.doc",
                locked: true
            )

            if let error = viewModel.errorMessage {
                ErrorStateView(message: error)
            }
        }
    }

    private var transcriptEditor: some View {
        PremiumCard {
            SectionHeader(title: "Live Transcript", subtitle: "Edit the transcript before saving family notes or executor instructions.")
            TextEditor(text: $viewModel.transcript)
                .frame(minHeight: 170)
                .padding(8)
                .background(LegacyTheme.deepNavy.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LegacyTheme.gold.opacity(0.2), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var generatedNotes: some View {
        if viewModel.summary.isEmpty == false || viewModel.familyNotes.isEmpty == false || viewModel.executorInstructions.isEmpty == false {
            PremiumCard {
                SectionHeader(title: "Generated Notes", subtitle: "Educational AI summary with professional-review guardrails.")
                if viewModel.summary.isEmpty == false {
                    note("Summary", viewModel.summary)
                }
                if viewModel.familyNotes.isEmpty == false {
                    note("Family Notes", viewModel.familyNotes)
                }
                if viewModel.executorInstructions.isEmpty == false {
                    note("Executor Instructions", viewModel.executorInstructions)
                }
            }
        }
    }

    private var previousRecordings: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Legacy Recordings", subtitle: "Saved personal wishes, family messages, and executor context.")
            if recordings.isEmpty {
                EmptyStateView(title: "No recordings yet", message: "Create a recording so family members have personal context alongside formal estate documents.", symbol: "waveform")
            } else {
                ForEach(recordings) { recording in
                    EstateReviewCard(
                        title: recording.title.isEmpty ? "Legacy recording" : recording.title,
                        summary: recording.summary.isEmpty ? recording.transcript : recording.summary,
                        score: nil
                    )
                }
            }
        }
    }

    private func note(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(LegacyTheme.paleGold)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
