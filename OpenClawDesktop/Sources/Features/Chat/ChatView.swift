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
            // Handle error silently for now
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

    private func handleEvent(_ event: GatewayEvent) {
        switch event.event {
        case GatewayEventType.agentStreaming:
            if let content = event.payload?.dictValue?["content"] as? String {
                streamingContent += content

                // Update or create streaming message
                if let lastIndex = messages.indices.last,
                   messages[lastIndex].role == .assistant && messages[lastIndex].id == "streaming" {
                    messages[lastIndex] = ChatMessage(
                        id: "streaming",
                        role: .assistant,
                        content: streamingContent,
                        timestamp: Date(),
                        model: event.payload?.dictValue?["model"] as? String,
                        tokens: nil
                    )
                } else {
                    messages.append(ChatMessage(
                        id: "streaming",
                        role: .assistant,
                        content: streamingContent,
                        timestamp: Date(),
                        model: event.payload?.dictValue?["model"] as? String,
                        tokens: nil
                    ))
                }
            }

        case GatewayEventType.agentComplete:
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
                    model: event.payload?.dictValue?["model"] as? String,
                    tokens: event.payload?.dictValue?["tokens"] as? Int
                )
            }
            streamingContent = ""

        case GatewayEventType.agentError:
            isAgentTyping = false
            streamingContent = ""

        default:
            break
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
