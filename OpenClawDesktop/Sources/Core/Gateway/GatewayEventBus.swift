import Foundation

@MainActor @Observable
final class GatewayEventBus {
    // MARK: - Agent Events
    var currentThinking: String = ""
    var thinkingHistory: [ThinkingBlock] = []
    var currentPlan: [PlanStep] = []
    var activeToolCalls: [ToolCallEvent] = []
    var subAgents: [SubAgentInfo] = []
    var isAgentActive: Bool = false
    var streamingContent: String = ""

    // MARK: - Types

    struct ThinkingBlock: Identifiable {
        let id = UUID()
        let timestamp: Date
        let content: String
        let type: ThinkingType

        enum ThinkingType: String {
            case thinking
            case planning
            case reasoning
        }
    }

    struct PlanStep: Identifiable {
        let id = UUID()
        let index: Int
        let description: String
        var status: StepStatus
        var detail: String?

        enum StepStatus: String {
            case pending
            case running
            case completed
            case failed
            case skipped
        }
    }

    struct ToolCallEvent: Identifiable {
        let id: String
        let timestamp: Date
        let toolName: String
        let input: String
        var output: String?
        var status: ToolStatus

        enum ToolStatus: String {
            case running
            case completed
            case failed
        }
    }

    struct SubAgentInfo: Identifiable {
        let id: String
        let purpose: String
        var status: SubAgentStatus
        var currentAction: String?
        let parentId: String?
        let spawnedAt: Date

        enum SubAgentStatus: String {
            case active
            case completed
            case failed
        }
    }

    // MARK: - Process Events

    nonisolated let gateway: GatewayClient

    init(gateway: GatewayClient) {
        self.gateway = gateway
    }

    func startListening() {
        Task {
            let stream = await gateway.eventStream()
            for await event in stream {
                processEvent(event)
            }
        }
    }

    /// Process incoming Gateway events.
    /// The real Gateway uses a single `chat` event that carries all streaming data
    /// (thinking, tool calls, text, completion). We parse the payload to determine
    /// the sub-type of chat update.
    private func processEvent(_ event: GatewayEvent) {
        switch event.event {
        case GatewayEventType.chat:
            processChatEvent(event)

        case GatewayEventType.systemPresence:
            // System presence events track instance availability
            if let dict = event.payload?.dictValue {
                let status = dict["status"] as? String
                if status == "online" {
                    // Agent instance came online
                } else if status == "offline" {
                    isAgentActive = false
                }
            }

        default:
            break
        }
    }

    /// Parse the `chat` event payload to determine what kind of update it is.
    /// The payload contains a `kind` field (or we infer from content) that tells us
    /// whether this is thinking, streaming text, a tool call, etc.
    private func processChatEvent(_ event: GatewayEvent) {
        guard let dict = event.payload?.dictValue else { return }

        // Determine the chat event kind from the payload
        let kind = dict["kind"] as? String
            ?? dict["type"] as? String
            ?? inferChatEventKind(from: dict)

        switch kind {
        case ChatEventKind.thinking.rawValue:
            if let content = dict["content"] as? String {
                currentThinking = content
                thinkingHistory.append(ThinkingBlock(
                    timestamp: Date(),
                    content: content,
                    type: .thinking
                ))
            }
            isAgentActive = true

        case ChatEventKind.streaming.rawValue:
            if let content = dict["content"] as? String {
                streamingContent += content
            }
            isAgentActive = true

        case ChatEventKind.toolCall.rawValue:
            let toolCall = ToolCallEvent(
                id: dict["id"] as? String ?? UUID().uuidString,
                timestamp: Date(),
                toolName: dict["name"] as? String ?? dict["tool"] as? String ?? "unknown",
                input: dict["input"] as? String ?? describeValue(dict["args"]),
                status: .running
            )
            activeToolCalls.append(toolCall)

        case ChatEventKind.toolResult.rawValue:
            if let toolId = dict["id"] as? String,
               let index = activeToolCalls.firstIndex(where: { $0.id == toolId }) {
                activeToolCalls[index].output = dict["result"] as? String ?? dict["output"] as? String
                let success = dict["success"] as? Bool ?? true
                activeToolCalls[index].status = success ? .completed : .failed
            }

        case ChatEventKind.complete.rawValue:
            isAgentActive = false

        case ChatEventKind.error.rawValue:
            isAgentActive = false

        case ChatEventKind.message.rawValue:
            // Full message (from history or final response)
            // This is handled by ChatViewModel for display
            break

        default:
            // Unknown chat sub-type - try to extract useful info
            if let content = dict["content"] as? String, !content.isEmpty {
                streamingContent += content
                isAgentActive = true
            }
        }
    }

    /// Infer the chat event kind from payload contents when no explicit kind is set.
    private func inferChatEventKind(from dict: [String: Any]) -> String {
        if dict["thinking"] != nil || dict["reasoning"] != nil {
            return ChatEventKind.thinking.rawValue
        }
        if dict["tool"] != nil || dict["name"] != nil && dict["args"] != nil {
            return ChatEventKind.toolCall.rawValue
        }
        if dict["result"] != nil || dict["output"] != nil {
            return ChatEventKind.toolResult.rawValue
        }
        if dict["done"] as? Bool == true || dict["finished"] as? Bool == true {
            return ChatEventKind.complete.rawValue
        }
        if dict["error"] != nil {
            return ChatEventKind.error.rawValue
        }
        if dict["content"] != nil {
            return ChatEventKind.streaming.rawValue
        }
        return ""
    }

    /// Convert a value to a string description for display
    private func describeValue(_ value: Any?) -> String {
        guard let value else { return "" }
        if let str = value as? String { return str }
        if let dict = value as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: value)
    }

    func reset() {
        currentThinking = ""
        thinkingHistory.removeAll()
        currentPlan.removeAll()
        activeToolCalls.removeAll()
        streamingContent = ""
        isAgentActive = false
    }
}
