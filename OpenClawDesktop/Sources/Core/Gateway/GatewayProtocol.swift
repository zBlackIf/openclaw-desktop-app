import Foundation

// MARK: - Gateway Message Types

enum GatewayMessageType: String, Codable {
    case req
    case res
    case event
}

// MARK: - Request

struct GatewayRequest: Codable {
    let type: String
    let id: String
    let method: String
    let params: AnyCodable?

    init(method: String, params: AnyCodable? = nil) {
        self.type = "req"
        self.id = UUID().uuidString
        self.method = method
        self.params = params
    }
}

// MARK: - Response

struct GatewayResponse: Codable, @unchecked Sendable {
    let type: String
    let id: String
    let ok: Bool
    let payload: AnyCodable?
    let error: GatewayError?
}

struct GatewayError: Codable {
    let code: String?
    let message: String?
}

// MARK: - Event

struct GatewayEvent: Codable, @unchecked Sendable {
    let type: String
    let event: String
    let payload: AnyCodable?
    let seq: Int?
    let stateVersion: Int?
}

// MARK: - Connect Handshake

struct ConnectRequest: Codable {
    let type: String
    let role: String
    let scopes: [String]
    let token: String?

    init(token: String? = nil) {
        self.type = "req"
        self.role = "operator"
        self.scopes = ["operator.read", "operator.write"]
        self.token = token
    }
}

// MARK: - RPC Methods

enum RPCMethod {
    // Config
    static let configGet = "config.get"
    static let configApply = "config.apply"
    static let configPatch = "config.patch"

    // Chat
    static let chatSend = "chat.send"
    static let chatHistory = "chat.history"
    static let chatInject = "chat.inject"

    // Sessions
    static let sessionsList = "sessions.list"
    static let sessionsHistory = "sessions.history"

    // Agent
    static let agentStatus = "agent.status"
    static let agentPause = "agent.pause"
    static let agentResume = "agent.resume"
    static let agentCancel = "agent.cancel"

    // Channels
    static let channelsList = "channels.list"
    static let channelsStatus = "channels.status"

    // Models
    static let modelsStatus = "models.status"
    static let modelsProviders = "models.providers"

    // Skills
    static let skillsList = "skills.list"
}

// MARK: - Event Types

enum GatewayEventType {
    static let agentThinking = "agent.thinking"
    static let agentStreaming = "agent.streaming"
    static let agentToolCall = "agent.tool_call"
    static let agentToolResult = "agent.tool_result"
    static let agentComplete = "agent.complete"
    static let agentError = "agent.error"
    static let agentPlanUpdate = "agent.plan_update"
    static let sessionUpdate = "session.update"
    static let channelUpdate = "channel.update"
    static let configUpdate = "config.update"
    static let subAgentSpawn = "agent.sub_spawn"
    static let subAgentComplete = "agent.sub_complete"
}

// MARK: - AnyCodable (lightweight any-type wrapper)

struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues(\.value)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    // Helper accessors
    var stringValue: String? { value as? String }
    var intValue: Int? { value as? Int }
    var boolValue: Bool? { value as? Bool }
    var doubleValue: Double? { value as? Double }
    var arrayValue: [Any]? { value as? [Any] }
    var dictValue: [String: Any]? { value as? [String: Any] }
}
