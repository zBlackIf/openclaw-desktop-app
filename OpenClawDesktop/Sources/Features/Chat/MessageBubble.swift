import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Role label
                HStack(spacing: 4) {
                    if message.role == .assistant {
                        Image(systemName: "brain")
                            .font(.caption2)
                    }
                    Text(roleLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let model = message.model {
                        Text("(\(shortModelName(model)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Content
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Tool calls
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    DisclosureGroup("Tool Calls (\(toolCalls.count))") {
                        ForEach(toolCalls) { toolCall in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(toolCall.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .fontDesign(.monospaced)
                                if let duration = toolCall.duration {
                                    Text("\(String(format: "%.1f", duration))s")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                // Token count
                if let tokens = message.tokens {
                    Text("\(tokens) tokens")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if message.role == .assistant || message.role == .system {
                Spacer(minLength: 60)
            }
        }
    }

    private var roleLabel: String {
        switch message.role {
        case .user: return "You"
        case .assistant: return "Assistant"
        case .system: return "System"
        case .tool: return "Tool"
        }
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user: return .blue.opacity(0.15)
        case .assistant: return Color(.controlBackgroundColor)
        case .system: return .yellow.opacity(0.1)
        case .tool: return .purple.opacity(0.1)
        }
    }

    private func shortModelName(_ model: String) -> String {
        if model.contains("/") {
            return String(model.split(separator: "/").last ?? Substring(model))
        }
        return model
    }
}
