import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            chatHeader

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isAgentTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            MessageInput(
                text: $viewModel.inputText,
                isDisabled: appState.connectionStatus != .connected,
                onSend: {
                    Task {
                        await viewModel.sendMessage(using: appState.sessionService)
                    }
                }
            )
        }
        .navigationTitle("Chat")
        .task {
            await viewModel.loadHistory(using: appState.sessionService)
            viewModel.startListening(gateway: appState.gatewayClient)
        }
    }

    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.currentSessionName)
                    .font(.headline)
                if !appState.currentModel.isEmpty {
                    Text(appState.currentModel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.isAgentTyping {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Thinking...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Session Picker
            Menu {
                ForEach(viewModel.sessions) { session in
                    Button(session.displayName) {
                        viewModel.switchSession(to: session.id)
                    }
                }
            } label: {
                Image(systemName: "rectangle.stack")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

@MainActor @Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isAgentTyping: Bool = false
    var currentSessionId: String?
    var currentSessionName: String = "Main Session"
    var sessions: [Session] = []
    var streamingContent: String = ""
    var errorMessage: String?

    func loadHistory(using service: SessionService) async {
        do {
            sessions = try await service.listSessions()
            if let mainSession = sessions.first(where: { $0.isMain }) {
                currentSessionId = mainSession.id
                currentSessionName = mainSession.displayName
            }
            if let sessionId = currentSessionId {
                messages = try await service.getHistory(sessionId: sessionId)
            }
        } catch {
            errorMessage = "Failed to load chat history: \(error.localizedDescription)"
        }
    }

    func sendMessage(using service: SessionService) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: text,
            timestamp: Date(),
            model: nil,
            tokens: nil
        )
        messages.append(userMessage)
        inputText = ""
        isAgentTyping = true

        do {
            try await service.sendMessage(text, sessionId: currentSessionId)
        } catch {
            isAgentTyping = false
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
    }

    func startListening(gateway: GatewayClient) {
        Task {
            let stream = await gateway.eventStream()
            for await event in stream {
                handleEvent(event)
            }
        }
    }

    /// Handle incoming events from the Gateway.
    /// The real Gateway sends a single `chat` event with different payload kinds.
    private func handleEvent(_ event: GatewayEvent) {
        guard event.event == GatewayEventType.chat else { return }
        guard let dict = event.payload?.dictValue else { return }

        // Determine what kind of chat update this is
        let kind = dict["kind"] as? String ?? dict["type"] as? String ?? ""

        switch kind {
        case ChatEventKind.streaming.rawValue, "":
            // Streaming text content
            if let content = dict["content"] as? String {
                streamingContent += content
                isAgentTyping = true
                updateOrCreateStreamingMessage(model: dict["model"] as? String)
            }

        case ChatEventKind.thinking.rawValue:
            // Agent is thinking - show typing indicator but don't add text
            isAgentTyping = true

        case ChatEventKind.complete.rawValue:
            isAgentTyping = false
            // Finalize the streaming message
            if let lastIndex = messages.indices.last,
               messages[lastIndex].id == "streaming" {
                let finalContent = streamingContent
                messages[lastIndex] = ChatMessage(
                    id: UUID().uuidString,
                    role: .assistant,
                    content: finalContent,
                    timestamp: Date(),
                    model: dict["model"] as? String,
                    tokens: dict["tokens"] as? Int
                )
            }
            streamingContent = ""

        case ChatEventKind.error.rawValue:
            isAgentTyping = false
            if let errorMsg = dict["message"] as? String ?? dict["error"] as? String {
                messages.append(ChatMessage(
                    id: UUID().uuidString,
                    role: .system,
                    content: "Error: \(errorMsg)",
                    timestamp: Date(),
                    model: nil,
                    tokens: nil
                ))
            }
            streamingContent = ""

        default:
            // For any other kind, try to extract content
            if let content = dict["content"] as? String, !content.isEmpty {
                streamingContent += content
                isAgentTyping = true
                updateOrCreateStreamingMessage(model: dict["model"] as? String)
            }
        }
    }

    private func updateOrCreateStreamingMessage(model: String?) {
        if let lastIndex = messages.indices.last,
           messages[lastIndex].role == .assistant && messages[lastIndex].id == "streaming" {
            messages[lastIndex] = ChatMessage(
                id: "streaming",
                role: .assistant,
                content: streamingContent,
                timestamp: Date(),
                model: model,
                tokens: nil
            )
        } else {
            messages.append(ChatMessage(
                id: "streaming",
                role: .assistant,
                content: streamingContent,
                timestamp: Date(),
                model: model,
                tokens: nil
            ))
        }
    }

    func switchSession(to sessionId: String) {
        currentSessionId = sessionId
        if let session = sessions.first(where: { $0.id == sessionId }) {
            currentSessionName = session.displayName
        }
        messages.removeAll()
        // Reload will happen via task
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                        .opacity(index <= dotCount ? 1.0 : 0.3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}
