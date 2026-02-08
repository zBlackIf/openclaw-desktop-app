import SwiftUI

struct SessionListView: View {
    @Environment(AppState.self) private var appState
    @State private var sessions: [Session] = []
    @State private var selectedSession: Session?
    @State private var isLoading = false

    var body: some View {
        HSplitView {
            // Session List
            VStack(spacing: 0) {
                HStack {
                    Text("Sessions")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await loadSessions() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Divider()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sessions.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack",
                        title: "No Sessions",
                        description: "Sessions will appear here when you start chatting or when messages arrive through channels"
                    )
                } else {
                    List(sessions, selection: $selectedSession) { session in
                        sessionRow(session)
                            .tag(session)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 250, maxWidth: 350)

            // Session Detail
            if let session = selectedSession {
                SessionDetailView(session: session)
            } else {
                EmptyStateView(
                    icon: "rectangle.stack",
                    title: "Select a Session",
                    description: "Choose a session from the list to view its details and history"
                )
            }
        }
        .navigationTitle("Sessions")
        .task {
            await loadSessions()
        }
    }

    private func sessionRow(_ session: Session) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if session.isMain {
                        StatusBadge(text: "Main", color: .blue)
                    }
                }

                HStack {
                    if let channel = session.channel {
                        Text(channel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let model = session.model {
                        Text(model)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                if let lastActivity = session.lastActivity {
                    Text(lastActivity, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Circle()
                    .fill(session.isActive ? .green : .gray)
                    .frame(width: 8, height: 8)
                Text("\(session.messageCount) msgs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadSessions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sessions = try await appState.sessionService.listSessions()
        } catch {
            sessions = []
        }
    }
}

// MARK: - Session Conformance

extension Session: Hashable {
    static func == (lhs: Session, rhs: Session) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: Session
    @Environment(AppState.self) private var appState
    @State private var messages: [ChatMessage] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(session.displayName)
                        .font(.headline)
                    HStack {
                        if let channel = session.channel {
                            Text(channel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if session.isMain {
                            StatusBadge(text: "Main Session", color: .blue)
                        }
                        StatusBadge(
                            text: session.isActive ? "Active" : "Inactive",
                            color: session.isActive ? .green : .gray
                        )
                    }
                }
                Spacer()
            }
            .padding()

            Divider()

            // Messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
        }
        .task {
            do {
                messages = try await appState.sessionService.getHistory(sessionId: session.id)
            } catch {
                messages = []
            }
        }
    }
}
