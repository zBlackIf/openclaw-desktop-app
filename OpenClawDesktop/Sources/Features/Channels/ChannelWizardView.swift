import SwiftUI

struct ChannelWizardView: View {
    let channelType: Channel.ChannelType
    let onComplete: () -> Void

    @Environment(AppState.self) private var appState
    @State private var currentStep = 0
    @State private var steps: [SetupStep]
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var tokenInput = ""
    @State private var allowFromInput = ""

    init(channelType: Channel.ChannelType, onComplete: @escaping () -> Void) {
        self.channelType = channelType
        self.onComplete = onComplete
        self._steps = State(initialValue: channelType.setupSteps)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            wizardHeader

            Divider()

            // Progress
            progressIndicator

            // Step Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if currentStep < steps.count {
                        stepContent(steps[currentStep])
                    }
                }
                .padding(24)
            }

            // Error
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(.red.opacity(0.05))
            }

            Divider()

            // Navigation
            HStack {
                Button("Cancel") {
                    onComplete()
                }

                Spacer()

                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                }

                if currentStep < steps.count - 1 {
                    Button("Next") {
                        completeCurrentStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                } else {
                    Button("Finish Setup") {
                        Task { await finishSetup() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    // MARK: - Wizard Header

    private var wizardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: channelType.icon)
                .font(.title)
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text("Setup \(channelType.rawValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                Rectangle()
                    .fill(stepColor(index))
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private func stepColor(_ index: Int) -> Color {
        if index < currentStep { return .green }
        if index == currentStep { return .blue }
        return Color(.separatorColor)
    }

    // MARK: - Step Content

    @ViewBuilder
    private func stepContent(_ step: SetupStep) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(step.title)
                .font(.headline)

            Text(step.description)
                .font(.body)
                .foregroundStyle(.secondary)

            // Dynamic input fields based on channel type and step
            switch channelType {
            case .telegram where currentStep == 1:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bot Token")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    SecureField("Paste your Telegram bot token", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                }

            case .discord where currentStep == 4:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bot Token")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    SecureField("Paste your Discord bot token", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                }

            case .whatsapp where currentStep == 2:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Allowed Phone Numbers")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Enter phone numbers (comma separated, e.g., +15555550123)", text: $allowFromInput)
                        .textFieldStyle(.roundedBorder)
                    Text("Only messages from these numbers will be processed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .slack where currentStep == 2:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bot Token")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    SecureField("xoxb-...", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                }

            default:
                EmptyView()
            }

            // Test Connection button for last steps
            if step.title.contains("Test") {
                Button {
                    Task { await testConnection() }
                } label: {
                    Label(
                        isProcessing ? "Testing..." : "Test Connection",
                        systemImage: isProcessing ? "arrow.clockwise" : "checkmark.circle"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
            }
        }
    }

    // MARK: - Actions

    private func completeCurrentStep() {
        steps[currentStep].isCompleted = true
        errorMessage = nil
        currentStep += 1
    }

    private func finishSetup() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            var config: [String: Any] = [:]

            switch channelType {
            case .telegram:
                config = ["token": tokenInput]
            case .discord:
                config = ["token": tokenInput]
            case .whatsapp:
                let numbers = allowFromInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                config = ["allowFrom": numbers]
            case .slack:
                config = ["token": tokenInput]
            default:
                break
            }

            try await appState.configService.setChannelConfig(
                channel: channelType.rawValue.lowercased(),
                config: config
            )

            steps[currentStep].isCompleted = true
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func testConnection() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await appState.gatewayClient.send(
                method: RPCMethod.channelsStatus,
                params: ["channel": channelType.rawValue.lowercased()]
            )
            if response.ok {
                errorMessage = nil
            } else {
                errorMessage = response.error?.message ?? "Connection test failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
