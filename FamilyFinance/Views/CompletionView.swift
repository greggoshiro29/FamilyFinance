import SwiftUI
import SwiftData

/// Mission complete screen shown after the game challenge.
struct CompletionView: View {
    let result: GameResult
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if result.isEmergencyExit {
                    emergencyExitContent
                } else {
                    successContent
                }

                Spacer()

                // Done button
                Button {
                    saveOccurrence()
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(result.isEmergencyExit ? Color.red : Color.cyan)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            if !result.isEmergencyExit {
                showConfetti = true
            }
        }
    }

    // MARK: - Success

    private var successContent: some View {
        VStack(spacing: 20) {
            // Large success icon
            Text("🎯")
                .font(.system(size: 80))
                .scaleEffect(showConfetti ? 1 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)

            Text("MISSION COMPLETE")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.cyan)

            Text("YOU'RE AWAKE!")
                .font(.title2)
                .foregroundColor(.white)

            // Stats
            VStack(spacing: 12) {
                StatRow(label: "Time", value: formatDuration(result.duration))
                StatRow(label: "Aliens Destroyed", value: "\(result.kills) / \(result.requiredKills)")
                StatRow(label: "Hits", value: "\(result.kills)")
                StatRow(label: "Misses", value: "\(result.misses)")
                StatRow(label: "Accuracy", value: String(format: "%.1f%%", result.accuracy))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
        }
    }

    // MARK: - Emergency Exit

    private var emergencyExitContent: some View {
        VStack(spacing: 20) {
            Text("⚠️")
                .font(.system(size: 80))

            Text("EMERGENCY DISMISSED")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.orange)

            Text("Alarm dismissed without completing the challenge.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if result.kills > 0 {
                VStack(spacing: 12) {
                    StatRow(label: "Time", value: formatDuration(result.duration))
                    StatRow(label: "Partial Kills", value: "\(result.kills) / \(result.requiredKills)")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 30)
            }
        }
    }

    // MARK: - Persistence

    private func saveOccurrence() {
        let status: CompletionStatus = result.isEmergencyExit ? .emergencyDismissed : .completed
        let occurrence = AlarmOccurrence(
            alarmID: result.alarmID,
            scheduledTime: result.completedAt,
            status: status,
            hits: result.kills,
            misses: result.misses,
            durationSeconds: result.duration
        )
        modelContext.insert(occurrence)
        try? modelContext.save()
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}