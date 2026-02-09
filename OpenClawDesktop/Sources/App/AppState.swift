import Foundation
import SwiftUI

@MainActor @Observable
final class AppState {
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let gatewayURL = "gatewayURL"
        static let authToken = "authToken"
        static let autoConnect = "autoConnect"
        static let lastNavItem = "lastNavItem"
    }

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

    var selectedNavItem: NavigationItem = .chat {
        didSet {
            UserDefaults.standard.set(selectedNavItem.rawValue, forKey: Keys.lastNavItem)
        }
    }

    // MARK: - Gateway Connection
    enum ConnectionStatus: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting..."
        case connected = "Connected"
        case reconnecting = "Reconnecting..."
        case error = "Error"
    }

    var connectionStatus: ConnectionStatus = .disconnected

    var gatewayURL: String = "ws://127.0.0.1:18789" {
        didSet {
            UserDefaults.standard.set(gatewayURL, forKey: Keys.gatewayURL)
        }
    }

    var authToken: String = "" {
        didSet {
            UserDefaults.standard.set(authToken, forKey: Keys.authToken)
        }
    }

    var autoConnect: Bool = true {
        didSet {
            UserDefaults.standard.set(autoConnect, forKey: Keys.autoConnect)
        }
    }

    // MARK: - Current Model
    var currentModel: String = ""
    var currentProvider: String = ""

    // MARK: - Agent State
    var isAgentRunning: Bool = false

    // MARK: - Error Handling
    var errorMessage: String?
    var showError: Bool = false

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

        // Restore persisted settings
        loadPersistedSettings()
    }

    private func loadPersistedSettings() {
        let defaults = UserDefaults.standard

        if let savedURL = defaults.string(forKey: Keys.gatewayURL), !savedURL.isEmpty {
            gatewayURL = savedURL
        }
        if let savedToken = defaults.string(forKey: Keys.authToken) {
            authToken = savedToken
        }
        if defaults.object(forKey: Keys.autoConnect) != nil {
            autoConnect = defaults.bool(forKey: Keys.autoConnect)
        }
        if let savedNav = defaults.string(forKey: Keys.lastNavItem),
           let navItem = NavigationItem(rawValue: savedNav) {
            selectedNavItem = navItem
        }
    }

    // MARK: - Error Display

    func showError(_ message: String) {
        errorMessage = message
        showError = true

        // Auto-dismiss after 5 seconds
        Task {
            try? await Task.sleep(for: .seconds(5))
            if errorMessage == message {
                showError = false
                errorMessage = nil
            }
        }
    }

    // MARK: - Connection

    func connect() async {
        connectionStatus = .connecting
        do {
            try await gatewayClient.connect(to: gatewayURL, token: authToken.isEmpty ? nil : authToken)
            connectionStatus = .connected
            await loadInitialData()
        } catch {
            connectionStatus = .error
            showError("Connection failed: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        await gatewayClient.disconnect()
        connectionStatus = .disconnected
    }

    /// Called on app launch - auto-connect if setting is enabled
    func connectIfNeeded() async {
        if autoConnect {
            await connect()
        }
    }

    private func loadInitialData() async {
        do {
            if let config = try await configService.getConfig() {
                currentModel = config.agent?.model ?? "Not configured"
                currentProvider = extractProvider(from: currentModel)
            }
        } catch {
            showError("Failed to load config: \(error.localizedDescription)")
        }
    }

    private func extractProvider(from model: String) -> String {
        if model.contains("/") {
            return String(model.split(separator: "/").first ?? "")
        }
        return "unknown"
    }
}
