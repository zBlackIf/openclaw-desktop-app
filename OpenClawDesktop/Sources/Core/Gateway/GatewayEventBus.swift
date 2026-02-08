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
        let id = UUID()
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
            case paused
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

    private func processEvent(_ event: GatewayEvent) {
        switch event.event {
        case GatewayEventType.agentThinking:
            if let content = event.payload?.dictValue?["content"] as? String {
                currentThinking = content
                thinkingHistory.append(ThinkingBlock(
                    timestamp: Date(),
                    content: content,
                    type: .thinking
                ))
            }
            isAgentActive = true

        case GatewayEventType.agentToolCall:
            if let dict = event.payload?.dictValue {
                let toolCall = ToolCallEvent(
                    timestamp: Date(),
                    toolName: dict["name"] as? String ?? "unknown",
                    input: dict["input"] as? String ?? "",
                    status: .running
                )
                activeToolCalls.append(toolCall)
            }

        case GatewayEventType.agentToolResult:
            if let dict = event.payload?.dictValue,
               let toolId = dict["id"] as? String,
               let index = activeToolCalls.firstIndex(where: { $0.toolName == toolId }) {
                activeToolCalls[index].output = dict["result"] as? String
                activeToolCalls[index].status = .completed
            }

        case GatewayEventType.agentPlanUpdate:
            if let steps = event.payload?.dictValue?["steps"] as? [[String: Any]] {
                currentPlan = steps.enumerated().map { index, step in
                    PlanStep(
                        index: index,
                        description: step["description"] as? String ?? "",
                        status: PlanStep.StepStatus(rawValue: step["status"] as? String ?? "pending") ?? .pending,
                        detail: step["detail"] as? String
                    )
                }
            }

        case GatewayEventType.agentComplete:
            isAgentActive = false

        case GatewayEventType.agentError:
            isAgentActive = false

        case GatewayEventType.subAgentSpawn:
            if let dict = event.payload?.dictValue {
                let subAgent = SubAgentInfo(
                    id: dict["id"] as? String ?? UUID().uuidString,
                    purpose: dict["purpose"] as? String ?? "Sub-agent",
                    status: .active,
                    currentAction: dict["action"] as? String,
                    parentId: dict["parentId"] as? String,
                    spawnedAt: Date()
                )
                subAgents.append(subAgent)
            }

        case GatewayEventType.subAgentComplete:
            if let dict = event.payload?.dictValue,
               let agentId = dict["id"] as? String,
               let index = subAgents.firstIndex(where: { $0.id == agentId }) {
                subAgents[index].status = .completed
            }

        default:
            break
        }
    }

    func reset() {
        currentThinking = ""
        thinkingHistory.removeAll()
        currentPlan.removeAll()
        activeToolCalls.removeAll()
        isAgentActive = false
    }
}
