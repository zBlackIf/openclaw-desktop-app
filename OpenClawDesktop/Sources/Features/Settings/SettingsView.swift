import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var gatewayURL: String = ""
    @State private var authToken: String = ""
    @State private var showAdvanced: Bool = false
    @State private var testResult: String?
    @State private var isTesting: Bool = false

    var body: some View {
        @Bindable var state = appState

        Form {
            // Gateway Connection
            Section("Gateway Connection") {
                TextField("Gateway URL", text: $gatewayURL)
                    .textFieldStyle(.roundedBorder)
                    .onAppear { gatewayURL = appState.gatewayURL }

                SecureField("Auth Token (optional)", text: $authToken)
                    .textFieldStyle(.roundedBorder)
                    .onAppear { authToken = appState.authToken }

                Toggle("Auto-connect on launch", isOn: $state.autoConnect)

                HStack {
                    Button("Test Connection") {
                        Task { await testConnection() }
                    }
                    .disabled(isTesting)

                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("Success") ? .green : .red)
                    }

                    Spacer()

                    Button("Save & Reconnect") {
                        appState.gatewayURL = gatewayURL
                        appState.authToken = authToken
                        Task {
                            await appState.disconnect()
                            await appState.connect()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Current Status
            Section("Status") {
                LabeledContent("Connection") {
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(appState.connectionStatus.rawValue)
                    }
                }

                LabeledContent("Current Model") {
                    Text(appState.currentModel.isEmpty ? "Not configured" : appState.currentModel)
                }

                LabeledContent("Agent") {
                    Text(appState.isAgentRunning ? "Running" : "Idle")
                }
            }

            // Advanced
            Section("Advanced") {
                DisclosureGroup("Advanced Settings", isExpanded: $showAdvanced) {
                    LabeledContent("Gateway URL") {
                        Text(appState.gatewayURL)
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }

                    LabeledContent("Config Path") {
                        Text("~/.openclaw/openclaw.json")
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }

                    Button("Open Config in Editor") {
                        let configPath = NSString("~/.openclaw/openclaw.json").expandingTildeInPath
                        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
                    }

                    Button("Open OpenClaw Docs") {
                        if let url = URL(string: "https://docs.openclaw.ai") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }

            // About
            Section("About") {
                LabeledContent("App Version") {
                    Text("1.0.0")
                }
                LabeledContent("OpenClaw") {
                    Link("github.com/openclaw/openclaw", destination: URL(string: "https://github.com/openclaw/openclaw")!)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    private var statusColor: Color {
        switch appState.connectionStatus {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil
        defer { isTesting = false }

        do {
            let testClient = GatewayClient()
            try await testClient.connect(to: gatewayURL, token: authToken.isEmpty ? nil : authToken)
            testResult = "Success - Connected!"
            await testClient.disconnect()
        } catch {
            testResult = "Failed: \(error.localizedDescription)"
        }
    }
}
