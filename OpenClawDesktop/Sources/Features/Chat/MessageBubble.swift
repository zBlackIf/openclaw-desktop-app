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

                // Content - rendered as Markdown
                MarkdownContentView(content: message.content, role: message.role)
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

// MARK: - Markdown Content View

/// Renders message content with Markdown support.
/// Uses AttributedString(markdown:) for inline formatting (bold, italic, code, links)
/// and splits out fenced code blocks for monospaced rendering with copy support.
struct MarkdownContentView: View {
    let content: String
    let role: ChatMessage.MessageRole

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(contentBlocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    Text(renderMarkdown(text))
                        .font(.body)
                        .textSelection(.enabled)

                case .codeBlock(let language, let code):
                    codeBlockView(language: language, code: code)
                }
            }
        }
    }

    // MARK: - Content Block Parsing

    private enum ContentBlock {
        case text(String)
        case codeBlock(language: String?, code: String)
    }

    /// Split content into text and fenced code blocks
    private var contentBlocks: [ContentBlock] {
        var blocks: [ContentBlock] = []
        let lines = content.components(separatedBy: "\n")
        var currentText = ""
        var inCodeBlock = false
        var codeLanguage: String?
        var codeContent = ""

        for line in lines {
            if line.hasPrefix("```") && !inCodeBlock {
                // Start of code block
                if !currentText.isEmpty {
                    blocks.append(.text(currentText.trimmingCharacters(in: .newlines)))
                    currentText = ""
                }
                inCodeBlock = true
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeLanguage = lang.isEmpty ? nil : lang
                codeContent = ""
            } else if line.hasPrefix("```") && inCodeBlock {
                // End of code block
                inCodeBlock = false
                blocks.append(.codeBlock(language: codeLanguage, code: codeContent.trimmingCharacters(in: .newlines)))
                codeLanguage = nil
                codeContent = ""
            } else if inCodeBlock {
                if !codeContent.isEmpty { codeContent += "\n" }
                codeContent += line
            } else {
                if !currentText.isEmpty { currentText += "\n" }
                currentText += line
            }
        }

        // Handle unclosed code block or remaining text
        if inCodeBlock {
            if !codeContent.isEmpty {
                blocks.append(.codeBlock(language: codeLanguage, code: codeContent.trimmingCharacters(in: .newlines)))
            }
        } else if !currentText.isEmpty {
            blocks.append(.text(currentText.trimmingCharacters(in: .newlines)))
        }

        return blocks
    }

    // MARK: - Markdown Rendering

    /// Render inline markdown (bold, italic, code, links) using AttributedString
    private func renderMarkdown(_ text: String) -> AttributedString {
        do {
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace
            return try AttributedString(markdown: text, options: options)
        } catch {
            return AttributedString(text)
        }
    }

    // MARK: - Code Block View

    private func codeBlockView(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar with language and copy button
            HStack {
                Text(language ?? "code")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.windowBackgroundColor).opacity(0.5))

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
            }
        }
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }
}
