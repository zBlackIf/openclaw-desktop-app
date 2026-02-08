import Foundation

@MainActor
final class SessionService: Sendable {
    nonisolated let gateway: GatewayClient

    init(gateway: GatewayClient) {
        self.gateway = gateway
    }

    func listSessions() async throws -> [Session] {
        let response = try await gateway.send(method: RPCMethod.sessionsList)
        guard response.ok, let payload = response.payload,
              let sessionsData = payload.arrayValue else { return [] }

        return sessionsData.compactMap { sessionDict -> Session? in
            guard let dict = sessionDict as? [String: Any] else { return nil }
            return Session(
                id: dict["id"] as? String ?? "",
                name: dict["name"] as? String,
                channel: dict["channel"] as? String,
                peer: dict["peer"] as? String,
                isMain: dict["isMain"] as? Bool ?? false,
                isActive: dict["isActive"] as? Bool ?? false,
                lastActivity: (dict["lastActivity"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) },
                messageCount: dict["messageCount"] as? Int ?? 0,
                model: dict["model"] as? String
            )
        }
    }

    func getHistory(sessionId: String, limit: Int = 50) async throws -> [ChatMessage] {
        let response = try await gateway.send(
            method: RPCMethod.chatHistory,
            params: ["sessionId": sessionId, "limit": limit]
        )
        guard response.ok, let payload = response.payload,
              let messagesData = payload.arrayValue else { return [] }

        return messagesData.compactMap { msgDict -> ChatMessage? in
            guard let dict = msgDict as? [String: Any] else { return nil }
            return ChatMessage(
                id: dict["id"] as? String ?? UUID().uuidString,
                role: ChatMessage.MessageRole(rawValue: dict["role"] as? String ?? "user") ?? .user,
                content: dict["content"] as? String ?? "",
                timestamp: (dict["timestamp"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date(),
                model: dict["model"] as? String,
                tokens: dict["tokens"] as? Int
            )
        }
    }

    func sendMessage(_ content: String, sessionId: String? = nil) async throws {
        var params: [String: Any] = ["content": content]
        if let sessionId {
            params["sessionId"] = sessionId
        }
        let response = try await gateway.send(method: RPCMethod.chatSend, params: params)
        if !response.ok {
            throw GatewayClient.ClientError.requestFailed(
                response.error?.message ?? "Failed to send message"
            )
        }
    }

    func injectMessage(_ content: String, sessionId: String? = nil) async throws {
        var params: [String: Any] = ["content": content]
        if let sessionId {
            params["sessionId"] = sessionId
        }
        let response = try await gateway.send(method: RPCMethod.chatInject, params: params)
        if !response.ok {
            throw GatewayClient.ClientError.requestFailed(
                response.error?.message ?? "Failed to inject message"
            )
        }
    }
}
