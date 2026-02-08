import SwiftUI

struct ThinkingProcessView: View {
    let eventBus: GatewayEventBus

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if eventBus.thinkingHistory.isEmpty {
                    EmptyStateView(
                        icon: "brain",
                        title: "No Thinking Activity",
                        description: "The agent's thinking process will appear here in real-time as it reasons through tasks"
                    )
                } else {
                    // Current thinking (live)
                    if !eventBus.currentThinking.isEmpty && eventBus.isAgentActive {
                        liveThinkingCard
                    }

                    // History
                    ForEach(eventBus.thinkingHistory.reversed()) { block in
                        thinkingBlockCard(block)
                    }
                }
            }
            .padding()
        }
    }

    private var liveThinkingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Thinking Now...")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                Spacer()
            }

            Text(eventBus.currentThinking)
                .font(.body)
                .textSelection(.enabled)
                .lineLimit(nil)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func thinkingBlockCard(_ block: GatewayEventBus.ThinkingBlock) -> some View {
        DisclosureGroup {
            Text(block.content)
                .font(.body)
                .textSelection(.enabled)
                .padding(.top, 4)
        } label: {
            HStack {
                typeIcon(block.type)
                Text(block.type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(block.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func typeIcon(_ type: GatewayEventBus.ThinkingBlock.ThinkingType) -> some View {
        switch type {
        case .thinking:
            Image(systemName: "brain")
                .foregroundStyle(.blue)
        case .planning:
            Image(systemName: "list.bullet.clipboard")
                .foregroundStyle(.purple)
        case .reasoning:
            Image(systemName: "lightbulb")
                .foregroundStyle(.yellow)
        }
    }
}
