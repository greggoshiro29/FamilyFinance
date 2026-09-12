import SwiftUI
import SwiftData

/// Main alarm list screen showing current time and all saved alarms.
struct AlarmListView: View {
    @Environment(AlarmListViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AlarmModel.time) private var alarms: [AlarmModel]

    @State private var showTestGame = false
    @AppStorage("testRequiredKills") private var testRequiredKills: Int = 10

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Current time header
                currentTimeHeader

                // Alarms list
                if alarms.isEmpty {
                    emptyState
                } else {
                    alarmsList
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadAlarms(context: modelContext)
            // Clamp any stale saved value into the valid stepper range so
            // leftover values from older builds (e.g. 5) can't display.
            testRequiredKills = min(max(testRequiredKills, 10), 35)
        }
        .fullScreenCover(isPresented: $showTestGame) {
            TestGameView(onDismiss: { showTestGame = false })
        }
    }

    // MARK: - Current Time

    private var currentTimeHeader: some View {
        VStack(spacing: 4) {
            // App logo — shown above the time (replaces the old
            // "ALARMPLAY: ALIEN INVASION" text header).
            ZStack {
                // Soft colored glow behind the logo lifts it off the black
                // background without washing out the artwork.
                Image("AlarmPlayLogo")
                    .resizable()
                    .scaledToFit()
                    .blur(radius: 8)
                    .brightness(0.25)
                    .opacity(0.5)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                Image("AlarmPlayLogo")
                    .resizable()
                    .scaledToFit()
            }
            .frame(maxWidth: 700)
            .padding(.bottom, 0)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

            Text(viewModel.currentTime, style: .time)
                .font(.system(size: 56, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .offset(y: -32)

            Text(viewModel.currentTime, style: .date)
                .font(.subheadline)
                .foregroundColor(.white)
                .offset(y: -32)
        }
        .padding(.top, 24)
        .padding(.bottom, 30)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundColor(.cyan.opacity(0.5))

            Text("No Alarms Set")
                .font(.title2)
                .foregroundColor(.white)

            Text("Tap + to create your first wake-up mission")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            addAlarmButton

            testGameControl
        }
    }

    // MARK: - Alarms List

    private var alarmsList: some View {
        List {
            ForEach(alarms) { alarm in
                AlarmRow(alarm: alarm)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteAlarm(alarm, context: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }

            // Add alarm button at bottom of list
            Section {
                addAlarmButton
                    .listRowBackground(Color.clear)
            }

            // Test game control
            Section {
                testGameControl
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var addAlarmButton: some View {
        Button {
            viewModel.editingAlarm = nil
            viewModel.showingAddAlarm = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Alarm")
                    .font(.title3)
            }
            .foregroundColor(.cyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
            )
        }
    }

    /// Quick-launch the shooter without scheduling an alarm. Includes an
    /// adjustable alien count for short test rounds.
    private var testGameControl: some View {
        VStack(spacing: 12) {
            Stepper("Aliens to destroy: \(testRequiredKills)", value: $testRequiredKills, in: 10...35)
                .font(.subheadline)
                .foregroundColor(.white)

            Button {
                showTestGame = true
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .font(.title2)
                    Text("Test Game")
                        .font(.title3)
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.borderless)

            // Settings — relocated to sit under the Test Game option.
            Button {
                viewModel.navigationPath.append("settings")
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                    Text("Settings")
                        .font(.title3)
                }
                .foregroundColor(.cyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Alarm Row

struct AlarmRow: View {
    @Environment(AlarmListViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    let alarm: AlarmModel
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack {
            // Time and label
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.formattedTime)
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .foregroundColor(alarm.isEnabled ? .white : .white.opacity(0.5))

                HStack(spacing: 6) {
                    Text(alarm.label)
                        .font(.subheadline)
                        .foregroundColor(alarm.isEnabled ? .white : .white.opacity(0.4))

                    if case .never = alarm.repeatSchedule {
                        // No repeat badge
                    } else {
                        Text(alarm.repeatSchedule.displayName)
                            .font(.caption2)
                            .foregroundColor(.cyan.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption2)
                    Text("\(alarm.requiredKills) kills")
                        .font(.caption2)
                    Text("•")
                    Text(alarm.difficulty.rawValue)
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in viewModel.toggleAlarm(alarm, context: modelContext) }
            ))
            .tint(.cyan)
            .labelsHidden()

            // Delete button
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundColor(.red.opacity(0.7))
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(alarm.label) alarm")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .alert("Delete Alarm?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteAlarm(alarm, context: modelContext)
            }
        } message: {
            Text("This alarm will be removed and its schedule cancelled.")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap an existing alarm -> open the EDIT screen only. Setting
            // showingAddAlarm here would stack a second (new-alarm) sheet.
            viewModel.editingAlarm = alarm
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(alarm.label) alarm at \(alarm.formattedTime). \(alarm.isEnabled ? "Enabled" : "Disabled")")
    }
}