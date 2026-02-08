import Foundation

// MARK: - Model Provider

struct ModelProvider: Identifiable, Codable {
    let id: String
    let name: String
    let models: [AIModel]
    var isAuthenticated: Bool
    var status: ProviderStatus

    enum ProviderStatus: String, Codable {
        case active
        case inactive
        case error
        case rateLimited = "rate_limited"
    }
}

struct AIModel: Identifiable, Codable {
    let id: String
    let name: String
    let provider: String
    let contextWindow: Int?
    let supportsVision: Bool
    let supportsThinking: Bool
    let description: String?

    var displayName: String {
        name
    }

    var providerAndModel: String {
        "\(provider)/\(id)"
    }
}

// MARK: - Well-known Models

extension AIModel {
    static let knownModels: [AIModel] = [
        // Anthropic
        AIModel(id: "claude-opus-4-6", name: "Claude Opus 4.6", provider: "anthropic",
                contextWindow: 200000, supportsVision: true, supportsThinking: true,
                description: "Most capable model for complex tasks"),
        AIModel(id: "claude-sonnet-4", name: "Claude Sonnet 4", provider: "anthropic",
                contextWindow: 200000, supportsVision: true, supportsThinking: true,
                description: "Balanced performance and speed"),
        AIModel(id: "claude-haiku-3.5", name: "Claude Haiku 3.5", provider: "anthropic",
                contextWindow: 200000, supportsVision: true, supportsThinking: false,
                description: "Fastest response times"),

        // OpenAI
        AIModel(id: "gpt-4o", name: "GPT-4o", provider: "openai",
                contextWindow: 128000, supportsVision: true, supportsThinking: false,
                description: "OpenAI's most capable model"),
        AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", provider: "openai",
                contextWindow: 128000, supportsVision: true, supportsThinking: false,
                description: "Cost-effective for simpler tasks"),
        AIModel(id: "o1", name: "o1", provider: "openai",
                contextWindow: 200000, supportsVision: true, supportsThinking: true,
                description: "Advanced reasoning model"),
    ]

    static func find(by id: String) -> AIModel? {
        knownModels.first { $0.id == id || $0.providerAndModel == id }
    }
}

// MARK: - Usage Tracking

struct ModelUsage: Identifiable {
    let id = UUID()
    let model: String
    let timestamp: Date
    let inputTokens: Int
    let outputTokens: Int
    let thinkingTokens: Int
    let sessionId: String?

    var totalTokens: Int {
        inputTokens + outputTokens + thinkingTokens
    }
}

struct UsageSummary {
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalThinkingTokens: Int
    let modelBreakdown: [String: Int] // model -> total tokens
    let period: DateInterval
}
