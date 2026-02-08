import SwiftUI

struct ChannelListView: View {
    @Environment(AppState.self) private var appState
    @State private var channels: [Channel] = []
    @State private var showWizard = false
    @State private var selectedChannelType: Channel.ChannelType?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Channels")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Connect messaging platforms to your AI assistant")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showWizard = true
                    } label: {
                        Label("Add Channel", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }

                // Connected Channels
                if !connectedChannels.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connected")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(connectedChannels) { channel in
                                connectedChannelCard(channel)
                            }
                        }
                    }
                }

                // Available Channels
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Channels")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(availableChannelTypes) { type in
                            availableChannelCard(type)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Channels")
        .sheet(isPresented: $showWizard) {
            if let type = selectedChannelType {
                ChannelWizardView(channelType: type) {
                    showWizard = false
                    Task { await loadChannels() }
                }
            } else {
                channelTypeSelector
            }
        }
        .task {
            await loadChannels()
        }
    }

    // MARK: - Connected Channel Card

    private func connectedChannelCard(_ channel: Channel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: channel.type.icon)
                    .font(.title2)
                Spacer()
                StatusBadge(
                    text: channel.status.rawValue.capitalized,
                    color: channelStatusColor(channel.status)
                )
            }

            Text(channel.type.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)

            if let lastActivity = channel.lastActivity {
                Text("Last active: \(lastActivity, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Settings") {
                    selectedChannelType = channel.type
                    showWizard = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Available Channel Card

    private func availableChannelCard(_ type: Channel.ChannelType) -> some View {
        Button {
            selectedChannelType = type
            showWizard = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color(.separatorColor))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Channel Type Selector (for wizard)

    private var channelTypeSelector: some View {
        VStack(spacing: 16) {
            Text("Choose a Channel")
                .font(.title2)
                .fontWeight(.bold)

            Text("Select a messaging platform to connect")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Channel.ChannelType.allCases) { type in
                    Button {
                        selectedChannelType = type
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title)
                            Text(type.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedChannelType == type
                            ? Color.blue.opacity(0.1)
                            : Color(.controlBackgroundColor)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedChannelType == type ? .blue : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()

            Button("Cancel") {
                showWizard = false
            }
            .padding()
        }
        .padding()
        .frame(width: 600, height: 500)
    }

    // MARK: - Helpers

    private func channelStatusColor(_ status: Channel.ChannelStatus) -> Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .gray
        case .connecting, .pairing: return .orange
        case .error: return .red
        }
    }

    private var connectedChannels: [Channel] {
        channels.filter { $0.status == .connected }
    }

    private var availableChannelTypes: [Channel.ChannelType] {
        let connectedTypes = Set(channels.map(\.type.rawValue))
        return Channel.ChannelType.allCases.filter { !connectedTypes.contains($0.rawValue) }
    }

    private func loadChannels() async {
        // Load channels from gateway
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await appState.gatewayClient.send(method: RPCMethod.channelsList)
            if response.ok, let payload = response.payload,
               let channelsData = payload.arrayValue {
                channels = channelsData.compactMap { channelDict -> Channel? in
                    guard let dict = channelDict as? [String: Any],
                          let typeStr = dict["type"] as? String,
                          let type = Channel.ChannelType(rawValue: typeStr) else { return nil }
                    return Channel(
                        id: dict["id"] as? String ?? UUID().uuidString,
                        type: type,
                        status: Channel.ChannelStatus(rawValue: dict["status"] as? String ?? "disconnected") ?? .disconnected,
                        connectedAccounts: dict["accounts"] as? [String] ?? []
                    )
                }
            }
        } catch {
            // Use empty list on error
        }
    }
}
