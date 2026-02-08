import Foundation

struct Session: Identifiable, Codable {
    let id: String
    let name: String?
    let channel: String?
    let peer: String?
    var isMain: Bool
    var isActive: Bool
    var lastActivity: Date?
    var messageCount: Int
    var model: String?

    var displayName: String {
        name ?? peer ?? channel ?? id
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    let model: String?
    let tokens: Int?
    var toolCalls: [ToolCallInfo]?

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
        case tool
    }
}

struct ToolCallInfo: Identifiable, Codable {
    let id: String
    let name: String
    let input: String?
    let output: String?
    let duration: TimeInterval?
}
