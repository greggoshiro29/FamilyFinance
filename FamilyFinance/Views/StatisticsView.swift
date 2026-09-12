import SwiftUI
import SwiftData

/// Wake-up history and statistics screen.
struct StatisticsView: View {
    @State private var vm = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                summaryCards
                    .padding(.top, 10)

                // History list
                historySection

                if vm.occurrences.isEmpty && !vm.isLoading {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Wake-Up History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.loadOccurrences(context: modelContext)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: "Completed", value: "\(vm.totalCompleted)", color: .cyan)
            StatCard(title: "Streak", value: "\(vm.currentStreak)", color: .green)
            StatCard(title: "Avg Time", value: vm.formattedAvgTime, color: .blue)
            StatCard(title: "Best Acc", value: vm.formattedBestAccuracy, color: .purple)
            StatCard(title: "Fastest", value: vm.formattedFastestTime, color: .orange)
            StatCard(title: "Accuracy", value: vm.overallHitRate, color: .pink)
            StatCard(title: "Emerg. Exits", value: "\(vm.totalEmergencyDismissed)", color: .red)
            StatCard(title: "Missed", value: "\(vm.totalMissed)", color: .gray)
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !vm.occurrences.isEmpty {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }

            ForEach(vm.occurrences.prefix(50)) { occurrence in
                OccurrenceRow(occurrence: occurrence)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "chart.bar.xscale")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            Text("No wake-up history yet")
                .font(.headline)
                .foregroundColor(.white)
            Text("Complete your first alarm challenge to see statistics here.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Occurrence Row

private struct OccurrenceRow: View {
    let occurrence: AlarmOccurrence

    var body: some View {
        HStack {
            // Status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(occurrence.scheduledTime.formattedTime12h)
                    .font(.body)
                    .foregroundColor(.white)

                Text(occurrence.scheduledTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(occurrence.formattedDuration)
                    .font(.body)
                    .foregroundColor(.white)

                if occurrence.status == .completed {
                    Text("\(occurrence.hits) hits • \(Int(occurrence.accuracy))%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }

    private var statusIcon: String {
        switch occurrence.status {
        case .completed: return "checkmark.circle.fill"
        case .emergencyDismissed: return "exclamationmark.triangle.fill"
        case .missed: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch occurrence.status {
        case .completed: return .green
        case .emergencyDismissed: return .orange
        case .missed: return .red
        }
    }
}