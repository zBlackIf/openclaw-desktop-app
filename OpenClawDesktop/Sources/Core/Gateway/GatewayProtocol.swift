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

// MARK: - Connect Handshake (aligned with real Gateway protocol)

/// The Gateway uses a `connect` RPC method for handshake.
/// Server may send a challenge first; client responds with connect request.
struct ConnectParams: Codable {
    let role: String
    let scopes: [String]
    let client: ClientInfo
    let auth: AuthInfo?
    let minProtocol: Int?
    let maxProtocol: Int?

    struct ClientInfo: Codable {
        let id: String
        let version: String
        let platform: String
        let mode: String
    }

    struct AuthInfo: Codable {
        let token: String?
        let password: String?
    }
}

/// Build the connect handshake request
func makeConnectRequest(token: String? = nil, password: String? = nil) -> GatewayRequest {
    let clientId = UUID().uuidString
    let params = ConnectParams(
        role: "operator",
        scopes: ["operator.read", "operator.write"],
        client: ConnectParams.ClientInfo(
            id: clientId,
            version: "0.2.0",
            platform: "macos",
            mode: "desktop"
        ),
        auth: (token != nil || password != nil) ? ConnectParams.AuthInfo(
            token: token,
            password: password
        ) : nil,
        minProtocol: 1,
        maxProtocol: 1
    )

    var dict: [String: Any] = [
        "role": params.role,
        "scopes": params.scopes,
        "client": [
            "id": params.client.id,
            "version": params.client.version,
            "platform": params.client.platform,
            "mode": params.client.mode
        ],
        "minProtocol": params.minProtocol ?? 1,
        "maxProtocol": params.maxProtocol ?? 1
    ]

    // Only include auth if we have credentials
    if let token {
        dict["auth"] = ["token": token]
    } else if let password {
        dict["auth"] = ["password": password]
    }

    return GatewayRequest(
        method: "connect",
        params: AnyCodable(dict)
    )
}

// MARK: - RPC Methods (aligned with real OpenClaw Gateway API)

enum RPCMethod {
    // Connection
    static let connect = "connect"

    // Config
    static let configGet = "config.get"
    static let configSet = "config.set"
    static let configUnset = "config.unset"
    static let configApply = "config.apply"
    static let configPatch = "config.patch"
    static let configSchema = "config.schema"

    // Chat
    static let chatSend = "chat.send"
    static let chatHistory = "chat.history"
    static let chatInject = "chat.inject"
    static let chatAbort = "chat.abort"

    // Sessions
    static let sessionsList = "sessions.list"
    static let sessionsPatch = "sessions.patch"

    // System
    static let status = "status"
    static let health = "health"
    static let logsTail = "logs.tail"

    // Channels
    static let channelsStatus = "channels.status"

    // Models
    static let modelsStatus = "models.status"
    static let modelsList = "models.list"

    // Nodes
    static let nodeList = "node.list"

    // Skills
    static let skillsList = "skills.list"
    static let skillsEnable = "skills.enable"
    static let skillsDisable = "skills.disable"

    // Cron
    static let cronList = "cron.list"
    static let cronStatus = "cron.status"
    static let cronAdd = "cron.add"
    static let cronUpdate = "cron.update"
    static let cronRemove = "cron.remove"
    static let cronRun = "cron.run"
    static let cronRuns = "cron.runs"

    // System Events
    static let systemEvent = "system.event"

    // Exec Approvals
    static let execApprovals = "exec.approvals"

    // Updates
    static let updateRun = "update.run"
}

// MARK: - Event Types (aligned with real OpenClaw Gateway)
// The real Gateway uses a `chat` event for all streaming data,
// and `system-presence` for instance availability.
// Individual fields in the `chat` event payload distinguish
// thinking, tool calls, streaming text, etc.

enum GatewayEventType {
    // Primary streaming event - carries all chat/agent activity
    static let chat = "chat"

    // System events
    static let systemPresence = "system-presence"

    // Hook/lifecycle events
    static let agentBootstrap = "agent.bootstrap"
    static let gatewayStartup = "gateway:startup"

    // Exec approval events
    static let execApprovalRequested = "exec.approval.requested"

    // Legacy/internal event names for event bus parsing
    // These are sub-types extracted from the `chat` event payload
    static let chatThinking = "chat.thinking"
    static let chatStreaming = "chat.streaming"
    static let chatToolCall = "chat.tool_call"
    static let chatToolResult = "chat.tool_result"
    static let chatComplete = "chat.complete"
    static let chatError = "chat.error"
}

// MARK: - Chat Event Payload Sub-Types
// The `chat` event carries different kinds of data in its payload.
// We parse the payload to determine what type of chat update it is.

enum ChatEventKind: String {
    case thinking       // Agent thinking/reasoning block
    case streaming      // Streaming text content
    case toolCall       // Tool call initiated
    case toolResult     // Tool call result returned
    case complete       // Agent turn complete
    case error          // Agent error
    case message        // Full message (from history or final)
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
