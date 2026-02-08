import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView {
            SidebarView()
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ConnectionIndicator(status: appState.connectionStatus)
            }
            ToolbarItem(placement: .automatic) {
                if !appState.currentModel.isEmpty && appState.currentModel != "Not configured" {
                    ModelBadge(model: appState.currentModel)
                }
            }
        }
        .task {
            await appState.connect()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNavItem {
        case .chat:
            ChatView()
        case .agentMonitor:
            AgentMonitorView()
        case .models:
            ModelConfigView()
        case .channels:
            ChannelListView()
        case .sessions:
            SessionListView()
        case .settings:
            SettingsView()
        }
    }
}

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        List(AppState.NavigationItem.allCases, selection: $state.selectedNavItem) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(appState.connectionStatus.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
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
