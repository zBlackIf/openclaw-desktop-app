import SwiftUI

struct PlanTreeView: View {
    let eventBus: GatewayEventBus

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if eventBus.currentPlan.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.clipboard",
                        title: "No Plan Available",
                        description: "The agent's execution plan will appear here when it creates one. You can monitor progress and modify upcoming steps."
                    )
                } else {
                    // Plan Header
                    HStack {
                        Text("Execution Plan")
                            .font(.headline)
                        Spacer()
                        Text("\(completedCount)/\(eventBus.currentPlan.count) steps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)

                    // Progress Bar
                    ProgressView(value: progress)
                        .tint(.blue)
                        .padding(.bottom, 8)

                    // Steps
                    ForEach(eventBus.currentPlan) { step in
                        planStepRow(step)
                    }
                }
            }
            .padding()
        }
    }

    private func planStepRow(_ step: GatewayEventBus.PlanStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Step indicator
            VStack(spacing: 0) {
                stepIcon(step.status)
                    .frame(width: 24, height: 24)

                if step.index < eventBus.currentPlan.count - 1 {
                    Rectangle()
                        .fill(step.status == .completed ? .green.opacity(0.3) : Color(.separatorColor))
                        .frame(width: 2, height: 24)
                }
            }

            // Step content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Step \(step.index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    StatusBadge(
                        text: step.status.rawValue.capitalized,
                        color: statusColor(step.status)
                    )
                }

                Text(step.description)
                    .font(.subheadline)
                    .fontWeight(step.status == .running ? .medium : .regular)

                if let detail = step.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(step.status == .skipped ? 0.5 : 1.0)
    }

    @ViewBuilder
    private func stepIcon(_ status: GatewayEventBus.PlanStep.StepStatus) -> some View {
        switch status {
        case .pending:
            Circle()
                .stroke(Color(.separatorColor), lineWidth: 2)
                .frame(width: 20, height: 20)
        case .running:
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 20, height: 20)
                ProgressView()
                    .scaleEffect(0.5)
            }
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.body)
        case .skipped:
            Image(systemName: "minus.circle")
                .foregroundStyle(.gray)
                .font(.body)
        }
    }

    private func statusColor(_ status: GatewayEventBus.PlanStep.StepStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .skipped: return .gray
        }
    }

    private var completedCount: Int {
        eventBus.currentPlan.filter { $0.status == .completed }.count
    }

    private var progress: Double {
        guard !eventBus.currentPlan.isEmpty else { return 0 }
        return Double(completedCount) / Double(eventBus.currentPlan.count)
    }
}
