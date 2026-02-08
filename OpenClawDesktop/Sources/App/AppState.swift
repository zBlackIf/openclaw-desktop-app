import Foundation
import SwiftUI

@MainActor @Observable
final class AppState {
    // MARK: - Navigation
    enum NavigationItem: String, CaseIterable, Identifiable {
        case chat = "Chat"
        case agentMonitor = "Agent Monitor"
        case models = "Models"
        case channels = "Channels"
        case sessions = "Sessions"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right"
            case .agentMonitor: return "brain"
            case .models: return "cpu"
            case .channels: return "antenna.radiowaves.left.and.right"
            case .sessions: return "rectangle.stack"
            case .settings: return "gear"
            }
        }
    }

    var selectedNavItem: NavigationItem = .chat

    // MARK: - Gateway Connection
    enum ConnectionStatus: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting..."
        case connected = "Connected"
        case reconnecting = "Reconnecting..."
        case error = "Error"
    }

    var connectionStatus: ConnectionStatus = .disconnected
    var gatewayURL: String = "ws://127.0.0.1:18789"
    var authToken: String = ""

    // MARK: - Current Model
    var currentModel: String = ""
    var currentProvider: String = ""

    // MARK: - Agent State
    var isAgentRunning: Bool = false
    var isAgentPaused: Bool = false

    // MARK: - Services
    let gatewayClient: GatewayClient
    let configService: ConfigService
    let sessionService: SessionService

    // MARK: - Menu Bar
    var menuBarIcon: String {
        switch connectionStatus {
        case .connected: return "brain.filled.head.profile"
        case .connecting, .reconnecting: return "brain.head.profile"
        case .disconnected, .error: return "brain.head.profile"
        }
    }

    init() {
        self.gatewayClient = GatewayClient()
        self.configService = ConfigService(gateway: gatewayClient)
        self.sessionService = SessionService(gateway: gatewayClient)
    }

    func connect() async {
        connectionStatus = .connecting
        do {
            try await gatewayClient.connect(to: gatewayURL, token: authToken.isEmpty ? nil : authToken)
            connectionStatus = .connected
            await loadInitialData()
        } catch {
            connectionStatus = .error
        }
    }

    func disconnect() async {
        await gatewayClient.disconnect()
        connectionStatus = .disconnected
    }

    private func loadInitialData() async {
        do {
            if let config = try await configService.getConfig() {
                currentModel = config.agent?.model ?? "Not configured"
                currentProvider = extractProvider(from: currentModel)
            }
        } catch {
            // Config load failed - non-fatal
        }
    }

    private func extractProvider(from model: String) -> String {
        if model.contains("/") {
            return String(model.split(separator: "/").first ?? "")
        }
        return "unknown"
    }
}
