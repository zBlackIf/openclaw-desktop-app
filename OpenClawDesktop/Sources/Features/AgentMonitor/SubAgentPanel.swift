import SwiftUI

struct SubAgentPanel: View {
    let eventBus: GatewayEventBus

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if eventBus.subAgents.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No Sub-Agents",
                        description: "Sub-agents spawned by the main agent will appear here. You can monitor their status and control them individually."
                    )
                } else {
                    // Summary
                    HStack {
                        Text("Active Sub-Agents")
                            .font(.headline)
                        Spacer()
                        Text("\(activeCount) active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Agent List (flat with indentation for children)
                    ForEach(sortedAgents) { agent in
                        subAgentCard(agent, depth: agentDepth(agent))
                    }
                }
            }
            .padding()
        }
    }

    private func subAgentCard(_ agent: GatewayEventBus.SubAgentInfo, depth: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Indentation
            if depth > 0 {
                HStack(spacing: 0) {
                    ForEach(0..<depth, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.separatorColor))
                            .frame(width: 2, height: 40)
                            .padding(.leading, 8)
                    }
                }
            }

            // Agent info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: agentIcon(agent.status))
                        .foregroundStyle(agentColor(agent.status))
                    Text(agent.purpose)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    StatusBadge(
                        text: agent.status.rawValue.capitalized,
                        color: agentColor(agent.status)
                    )
                }

                if let action = agent.currentAction {
                    Text(action)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Started \(agent.spawnedAt, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    if agent.status == .active {
                        Button {
                            // Pause sub-agent
                        } label: {
                            Image(systemName: "pause.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Pause this sub-agent")

                        Button {
                            // Cancel sub-agent
                        } label: {
                            Image(systemName: "stop.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .help("Cancel this sub-agent")
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func agentIcon(_ status: GatewayEventBus.SubAgentInfo.SubAgentStatus) -> String {
        switch status {
        case .active: return "person.fill.questionmark"
        case .completed: return "person.fill.checkmark"
        case .failed: return "person.fill.xmark"
        }
    }

    private func agentColor(_ status: GatewayEventBus.SubAgentInfo.SubAgentStatus) -> Color {
        switch status {
        case .active: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    private var sortedAgents: [GatewayEventBus.SubAgentInfo] {
        // Flatten tree: root agents first, then their children
        var result: [GatewayEventBus.SubAgentInfo] = []
        let roots = eventBus.subAgents.filter { $0.parentId == nil }
        for root in roots {
            result.append(root)
            let children = eventBus.subAgents.filter { $0.parentId == root.id }
            result.append(contentsOf: children)
        }
        // Add any orphans
        let addedIds = Set(result.map(\.id))
        for agent in eventBus.subAgents where !addedIds.contains(agent.id) {
            result.append(agent)
        }
        return result
    }

    private func agentDepth(_ agent: GatewayEventBus.SubAgentInfo) -> Int {
        agent.parentId == nil ? 0 : 1
    }

    private var activeCount: Int {
        eventBus.subAgents.filter { $0.status == .active }.count
    }
}
