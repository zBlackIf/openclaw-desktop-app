import Foundation

actor GatewayClient {
    // MARK: - Types

    enum ClientError: Error, LocalizedError {
        case notConnected
        case connectionFailed(String)
        case requestTimeout
        case requestFailed(String)
        case invalidResponse
        case handshakeFailed(String)

        var errorDescription: String? {
            switch self {
            case .notConnected: return "Not connected to Gateway"
            case .connectionFailed(let msg): return "Connection failed: \(msg)"
            case .requestTimeout: return "Request timed out"
            case .requestFailed(let msg): return "Request failed: \(msg)"
            case .invalidResponse: return "Invalid response from Gateway"
            case .handshakeFailed(let msg): return "Handshake failed: \(msg)"
            }
        }
    }

    // MARK: - Properties

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var pendingRequests: [String: CheckedContinuation<GatewayResponse, Error>] = [:]
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var currentURL: String?
    private var currentToken: String?
    private var receiveTask: Task<Void, Never>?

    // Event stream for SwiftUI observation
    private var eventContinuations: [UUID: AsyncStream<GatewayEvent>.Continuation] = [:]

    // MARK: - Connection

    func connect(to url: String, token: String? = nil) async throws {
        currentURL = url
        currentToken = token

        guard let wsURL = URL(string: url) else {
            throw ClientError.connectionFailed("Invalid URL: \(url)")
        }

        let session = URLSession(configuration: .default)
        self.urlSession = session
        let task = session.webSocketTask(with: wsURL)
        self.webSocket = task
        task.resume()

        // Send proper connect handshake (aligned with real Gateway protocol)
        let connectReq = makeConnectRequest(token: token)
        let encoder = JSONEncoder()
        let data = try encoder.encode(connectReq)
        let message = URLSessionWebSocketTask.Message.string(String(data: data, encoding: .utf8)!)
        try await task.send(message)

        // Wait for hello-ok response
        let response = try await task.receive()
        switch response {
        case .string(let text):
            if let responseData = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                // Check for successful handshake
                if let ok = json["ok"] as? Bool, ok {
                    // Handshake successful
                } else if let error = json["error"] as? [String: Any] {
                    let msg = error["message"] as? String ?? "Unknown handshake error"
                    throw ClientError.handshakeFailed(msg)
                }
                // Also accept if type is "res" with ok:true (standard response)
            }
        case .data:
            break // Unexpected but continue
        @unknown default:
            break
        }

        isConnected = true
        reconnectAttempts = 0

        // Start receiving messages
        receiveTask = Task { [weak self] in
            await self?.receiveMessages()
        }
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false

        // Cancel all pending requests
        for (_, continuation) in pendingRequests {
            continuation.resume(throwing: ClientError.notConnected)
        }
        pendingRequests.removeAll()
    }

    // MARK: - Send Request

    func send(method: String, params: sending [String: Any]? = nil) async throws -> GatewayResponse {
        guard isConnected, let ws = webSocket else {
            throw ClientError.notConnected
        }

        let request = GatewayRequest(
            method: method,
            params: params.map { AnyCodable($0) }
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let message = URLSessionWebSocketTask.Message.string(String(data: data, encoding: .utf8)!)
        try await ws.send(message)

        // Wait for response with timeout
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[request.id] = continuation

            // Timeout after 30 seconds
            Task {
                try await Task.sleep(for: .seconds(30))
                if let pending = pendingRequests.removeValue(forKey: request.id) {
                    pending.resume(throwing: ClientError.requestTimeout)
                }
            }
        }
    }

    // MARK: - Send JSON (Sendable-safe alternative)

    func sendJSON(method: String, jsonData: Data) async throws -> GatewayResponse {
        // Deserialize on the actor side to avoid Sendable issues with [String: Any]
        let params = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        return try await send(method: method, params: params)
    }

    // MARK: - Event Stream

    func eventStream() -> AsyncStream<GatewayEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            eventContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeEventContinuation(id: id)
                }
            }
        }
    }

    private func removeEventContinuation(id: UUID) {
        eventContinuations.removeValue(forKey: id)
    }

    // MARK: - Receive Loop

    private func receiveMessages() async {
        guard let ws = webSocket else { return }

        while !Task.isCancelled {
            do {
                let message = try await ws.receive()
                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    isConnected = false
                    await attemptReconnect()
                }
                return
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        let decoder = JSONDecoder()

        // Try to determine message type
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let type = json["type"] as? String {

            switch type {
            case "res":
                if let response = try? decoder.decode(GatewayResponse.self, from: data) {
                    if let continuation = pendingRequests.removeValue(forKey: response.id) {
                        continuation.resume(returning: response)
                    }
                }
            case "event":
                if let event = try? decoder.decode(GatewayEvent.self, from: data) {
                    for (_, continuation) in eventContinuations {
                        continuation.yield(event)
                    }
                }
            default:
                break
            }
        }
    }

    // MARK: - Reconnection

    private func attemptReconnect() async {
        guard reconnectAttempts < maxReconnectAttempts,
              let url = currentURL else { return }

        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 60.0) // Exponential backoff, max 60s

        try? await Task.sleep(for: .seconds(delay))

        do {
            try await connect(to: url, token: currentToken)
        } catch {
            await attemptReconnect()
        }
    }

    // MARK: - Connection Status

    var connected: Bool {
        isConnected
    }
}
