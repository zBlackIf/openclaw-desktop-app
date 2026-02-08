import Foundation

// MARK: - OpenClaw Configuration Model
// Represents the structure of ~/.openclaw/openclaw.json

struct OpenClawConfig: Codable {
    var agent: AgentConfig?
    var channels: ChannelsConfig?
    var messages: MessagesConfig?
    var sessions: SessionsConfig?
    var tools: ToolsConfig?
    var sandbox: SandboxConfig?
}

struct AgentConfig: Codable {
    var model: String?
    var workspace: String?
    var thinking: ThinkingConfig?
    var timeout: Int?
    var maxConcurrent: Int?
    var identity: IdentityConfig?
}

struct ThinkingConfig: Codable {
    var enabled: Bool?
    var level: String? // "low", "medium", "high"
}

struct IdentityConfig: Codable {
    var name: String?
    var personality: String?
}

struct ChannelsConfig: Codable {
    var whatsapp: ChannelConfig?
    var telegram: ChannelConfig?
    var discord: ChannelConfig?
    var slack: ChannelConfig?
    var signal: ChannelConfig?
    var webchat: ChannelConfig?
    var teams: ChannelConfig?
    var matrix: ChannelConfig?
}

struct ChannelConfig: Codable {
    var enabled: Bool?
    var allowFrom: [String]?
    var mentionRequired: Bool?
    var groupHistoryLimit: Int?
    var pairingRequired: Bool?
    var token: String?
}

struct MessagesConfig: Codable {
    var debounceMs: Int?
    var responsePrefix: String?
    var ackReaction: String?
}

struct SessionsConfig: Codable {
    var scope: String? // "per-sender", "per-channel", "shared"
    var resetTrigger: String? // "daily", "idle"
    var idleTimeoutMinutes: Int?
}

struct ToolsConfig: Codable {
    var allow: [String]?
    var deny: [String]?
}

struct SandboxConfig: Codable {
    var mode: String? // "none", "non-main", "all"
    var docker: DockerConfig?
}

struct DockerConfig: Codable {
    var image: String?
    var memoryLimit: String?
}
