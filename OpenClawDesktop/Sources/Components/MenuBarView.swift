import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Connection Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.connectionStatus.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 4)

            Divider()

            // Current Model
            if !appState.currentModel.isEmpty {
                HStack {
                    Image(systemName: "cpu")
                        .font(.caption)
                    Text(appState.currentModel)
                        .font(.caption)
                }
                .padding(.horizontal, 4)
            }

            // Agent Status
            if appState.isAgentRunning {
                HStack {
                    Image(systemName: "brain")
                        .font(.caption)
                    Text("Agent Running")
                        .font(.caption)
                }
                .padding(.horizontal, 4)
            }

            Divider()

            // Quick Actions
            Button("Open OpenClaw") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut("o")

            Button("Reconnect") {
                Task {
                    await appState.disconnect()
                    await appState.connect()
                }
            }

            Divider()

            Button("Quit OpenClaw Desktop") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private var statusColor: Color {
        switch appState.connectionStatus {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
