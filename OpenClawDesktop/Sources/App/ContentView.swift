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
        .overlay(alignment: .top) {
            // Error banner overlay
            if appState.showError, let message = appState.errorMessage {
                ErrorBannerView(message: message) {
                    appState.showError = false
                    appState.errorMessage = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: appState.showError)
                .padding(.top, 8)
                .padding(.horizontal)
            }
        }
        .task {
            await appState.connectIfNeeded()
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

// MARK: - Error Banner

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
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
