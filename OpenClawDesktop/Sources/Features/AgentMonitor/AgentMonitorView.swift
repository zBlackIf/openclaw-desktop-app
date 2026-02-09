import SwiftUI

struct AgentMonitorView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: MonitorTab = .thinking
    @State private var injectText: String = ""

    enum MonitorTab: String, CaseIterable {
        case thinking = "Thinking"
        case plan = "Plan"
        case tools = "Tools"
        case subAgents = "Sub-Agents"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status Bar
            agentStatusBar

            Divider()

            // Tab Selector
            Picker("", selection: $selectedTab) {
                ForEach(MonitorTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab Content
            tabContent

            Divider()

            // Inject Context Bar
            injectBar
        }
        .navigationTitle("Agent Monitor")
    }

    // MARK: - Status Bar

    private var agentStatusBar: some View {
        HStack {
            HStack(spacing: 8) {
                if appState.eventBus.isAgentActive {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Agent Active")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                } else {
                    Circle()
                        .fill(.gray)
                        .frame(width: 8, height: 8)
                    Text("Agent Idle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Control Buttons
            HStack(spacing: 8) {
                Button {
                    Task { await abortAgent() }
                } label: {
                    Image(systemName: "stop.fill")
                }
                .disabled(!appState.eventBus.isAgentActive)
                .tint(.red)
                .help("Abort Agent Run")

                Button {
                    appState.eventBus.reset()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Clear Monitor")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        let bus = appState.eventBus
        switch selectedTab {
        case .thinking:
            ThinkingProcessView(eventBus: bus)
        case .plan:
            PlanTreeView(eventBus: bus)
        case .tools:
            toolCallsView(bus)
        case .subAgents:
            SubAgentPanel(eventBus: bus)
        }
    }

    private func toolCallsView(_ bus: GatewayEventBus) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if bus.activeToolCalls.isEmpty {
                    EmptyStateView(
                        icon: "wrench.and.screwdriver",
                        title: "No Tool Calls",
                        description: "Tool calls will appear here when the agent uses tools"
                    )
                } else {
                    ForEach(bus.activeToolCalls) { toolCall in
                        toolCallRow(toolCall)
                    }
                }
            }
            .padding()
        }
    }

    private func toolCallRow(_ toolCall: GatewayEventBus.ToolCallEvent) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                if !toolCall.input.isEmpty {
                    Text("Input:")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(toolCall.input)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .textSelection(.enabled)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if let output = toolCall.output {
                    Text("Output:")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(output)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .textSelection(.enabled)
                        .lineLimit(10)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        } label: {
            HStack {
                statusIcon(for: toolCall.status)
                Text(toolCall.toolName)
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                Spacer()
                Text(toolCall.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statusIcon(for status: GatewayEventBus.ToolCallEvent.ToolStatus) -> some View {
        Group {
            switch status {
            case .running:
                ProgressView().scaleEffect(0.6)
            case .completed:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            }
        }
        .font(.caption)
    }

    // MARK: - Inject Bar

    private var injectBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "syringe")
                .foregroundStyle(.secondary)
            TextField("Inject context or instructions...", text: $injectText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await injectContext() }
                }
            Button("Inject") {
                Task { await injectContext() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(injectText.isEmpty)
        }
        .padding(10)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Actions

    private func abortAgent() async {
        do {
            _ = try await appState.gatewayClient.send(method: RPCMethod.chatAbort)
            appState.isAgentRunning = false
        } catch {
            appState.showError("Failed to abort agent: \(error.localizedDescription)")
        }
    }

    private func injectContext() async {
        let text = injectText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            try await appState.sessionService.injectMessage(text)
            injectText = ""
        } catch {
            appState.showError("Failed to inject context: \(error.localizedDescription)")
        }
    }
}
