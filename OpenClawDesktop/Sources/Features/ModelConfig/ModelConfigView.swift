import SwiftUI

struct ModelConfigView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ModelConfigViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Model Card
                currentModelCard

                // Provider Sections
                ForEach(viewModel.providers) { provider in
                    providerSection(provider)
                }

                // Usage Dashboard
                usageSection
            }
            .padding()
        }
        .navigationTitle("Models")
        .task {
            await viewModel.load(using: appState.configService)
        }
    }

    // MARK: - Current Model Card

    private var currentModelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Model")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.currentModel?.displayName ?? appState.currentModel)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Spacer()
                StatusBadge(
                    text: appState.connectionStatus == .connected ? "Active" : "Inactive",
                    color: appState.connectionStatus == .connected ? .green : .gray
                )
            }

            if let model = viewModel.currentModel {
                HStack(spacing: 16) {
                    modelCapability(icon: "text.magnifyingglass",
                                   label: "Context",
                                   value: formatContextWindow(model.contextWindow ?? 0))
                    if model.supportsVision {
                        modelCapability(icon: "eye", label: "Vision", value: "Yes")
                    }
                    if model.supportsThinking {
                        modelCapability(icon: "brain", label: "Thinking", value: "Yes")
                    }
                }
            }

            // Quick Switch
            HStack {
                Text("Quick Switch:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(AIModel.knownModels.prefix(4)) { model in
                    Button(model.name) {
                        Task {
                            await viewModel.switchModel(to: model, using: appState.configService)
                            appState.currentModel = model.providerAndModel
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(model.providerAndModel == appState.currentModel)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Provider Section

    private func providerSection(_ provider: ModelProvider) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(provider.name)
                    .font(.headline)
                Spacer()
                StatusBadge(
                    text: provider.isAuthenticated ? "Connected" : "Not Connected",
                    color: provider.isAuthenticated ? .green : .orange
                )
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(provider.models) { model in
                    modelCard(model)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func modelCard(_ model: AIModel) -> some View {
        Button {
            Task {
                await viewModel.switchModel(to: model, using: appState.configService)
                appState.currentModel = model.providerAndModel
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(model.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if model.providerAndModel == appState.currentModel {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }

                if let desc = model.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let ctx = model.contextWindow {
                        Label(formatContextWindow(ctx), systemImage: "text.magnifyingglass")
                            .font(.caption2)
                    }
                    if model.supportsVision {
                        Label("Vision", systemImage: "eye")
                            .font(.caption2)
                    }
                    if model.supportsThinking {
                        Label("Thinking", systemImage: "brain")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(
                model.providerAndModel == appState.currentModel
                ? Color.blue.opacity(0.1)
                : Color(.windowBackgroundColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        model.providerAndModel == appState.currentModel ? .blue : .clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Usage Section

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage")
                .font(.headline)

            if viewModel.usageHistory.isEmpty {
                Text("No usage data yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.usageHistory) { usage in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(usage.model)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(usage.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(usage.totalTokens) tokens")
                                .font(.caption)
                            Text("In: \(usage.inputTokens) / Out: \(usage.outputTokens)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func modelCapability(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(label): \(value)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatContextWindow(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return "\(tokens / 1_000_000)M"
        } else if tokens >= 1000 {
            return "\(tokens / 1000)K"
        }
        return "\(tokens)"
    }
}

@MainActor @Observable
class ModelConfigViewModel {
    var providers: [ModelProvider] = []
    var currentModel: AIModel?
    var usageHistory: [ModelUsage] = []
    var isLoading = false
    var errorMessage: String?

    func load(using configService: ConfigService) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let config = try await configService.getConfig() {
                let modelId = config.agent?.model ?? ""
                currentModel = AIModel.find(by: modelId)
            }
        } catch {
            errorMessage = "Failed to load model config: \(error.localizedDescription)"
        }

        // Initialize with known providers
        providers = [
            ModelProvider(
                id: "anthropic",
                name: "Anthropic",
                models: AIModel.knownModels.filter { $0.provider == "anthropic" },
                isAuthenticated: currentModel?.provider == "anthropic",
                status: .active
            ),
            ModelProvider(
                id: "openai",
                name: "OpenAI",
                models: AIModel.knownModels.filter { $0.provider == "openai" },
                isAuthenticated: currentModel?.provider == "openai",
                status: .active
            )
        ]
    }

    func switchModel(to model: AIModel, using configService: ConfigService) async {
        do {
            try await configService.setModel(model.providerAndModel)
            currentModel = model
            errorMessage = nil
        } catch {
            errorMessage = "Failed to switch model: \(error.localizedDescription)"
        }
    }
}
