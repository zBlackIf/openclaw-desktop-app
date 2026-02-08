import SwiftUI

struct ConnectionIndicator: View {
    let status: AppState.ConnectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay {
                    if status == .connecting || status == .reconnecting {
                        Circle()
                            .stroke(statusColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 14, height: 14)
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: status)
                    }
                }
            Text(status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var pulseScale: CGFloat {
        status == .connecting || status == .reconnecting ? 1.5 : 1.0
    }

    private var pulseOpacity: Double {
        status == .connecting || status == .reconnecting ? 0.0 : 1.0
    }
}

struct ModelBadge: View {
    let model: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu")
                .font(.caption2)
            Text(shortModelName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.blue.opacity(0.1))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }

    private var shortModelName: String {
        if model.contains("/") {
            return String(model.split(separator: "/").last ?? Substring(model))
        }
        return model
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var action: (() -> Void)?
    var actionLabel: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            if let action, let actionLabel {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
