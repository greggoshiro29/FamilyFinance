import SwiftUI

/// App settings screen for default values, permissions, and testing.
struct SettingsView: View {
    @State private var vm = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showTestGame = false

    var body: some View {
        Form {
            // Defaults
            Section("Default Alarm Settings") {
                Picker("Default Sound", selection: $vm.defaultAlarmSound) {
                    ForEach(AlarmSound.allCases, id: \.rawValue) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }

                Picker("Default Difficulty", selection: $vm.defaultDifficulty) {
                    ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                        Text(diff.rawValue).tag(diff)
                    }
                }

                Stepper("Default Aliens: \(vm.defaultRequiredKills)",
                        value: $vm.defaultRequiredKills, in: 10...100)

                Toggle("Vibration", isOn: $vm.defaultVibration)
                    .tint(.cyan)
            }

            // Emergency Exit
            Section {
                Toggle("Emergency Exit", isOn: $vm.emergencyExitEnabled)
                    .tint(.cyan)
            } header: {
                Text("Safety")
            } footer: {
                Text("When enabled, a small Emergency Exit button appears during the game. Press and hold for 5 seconds to dismiss the alarm without completing the challenge.")
            }

            // Permissions
            Section("Permissions") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .foregroundColor(.primary)
                        Text(notificationStatusText)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                    Spacer()
                    if vm.notificationStatus != .authorized {
                        Button("Enable") {
                            Task { await vm.requestPermissions() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .controlSize(.small)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AlarmKit")
                        Text(vm.isAlarmKitAvailable ? "Available (iOS 26+)" : "Using Notification Fallback")
                            .font(.caption)
                            .foregroundColor(vm.isAlarmKitAvailable ? .green : .orange)
                    }
                    Spacer()
                }

                Button("Open System Settings") {
                    vm.openSystemSettings()
                }
                .foregroundColor(.cyan)
            }

            // Testing
            Section("Testing") {
                Button {
                    vm.testAlarm()
                } label: {
                    HStack {
                        Image(systemName: "alarm.fill")
                        Text("Test Alarm Sound")
                    }
                    .foregroundColor(.cyan)
                }

                Button {
                    showTestGame = true
                } label: {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                        Text("Test Game (No Alarm)")
                    }
                    .foregroundColor(.cyan)
                }
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.white)
                }

                NavigationLink("Privacy Policy") {
                    privacyView
                }
            }

            // Reset
            Section {
                Button("Reset Onboarding") {
                    vm.resetOnboarding()
                }
                .foregroundColor(.orange)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await vm.refreshPermissionStatus() }
        }
        .fullScreenCover(isPresented: $showTestGame) {
            TestGameView(onDismiss: { showTestGame = false })
        }
    }

    // MARK: - Permission Status

    private var notificationStatusText: String {
        switch vm.notificationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private var statusColor: Color {
        switch vm.notificationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }

    // MARK: - Privacy

    private var privacyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("AlarmPlay: Alien Invasion stores all data locally on your device. No data is collected, transmitted, or shared with any third party.")
                    .foregroundColor(.white)

                Text("Data Stored Locally:")
                    .fontWeight(.semibold)

                Text("• Alarm settings (time, label, repeat schedule, sound preferences)\n• Wake-up challenge statistics (hits, misses, completion times)\n• Challenge difficulty and target count preferences\n• Onboarding completion status")
                    .foregroundColor(.white)

                Text("Permissions:")
                    .fontWeight(.semibold)

                Text("• Notifications: Required to fire alarms at scheduled times\n• Critical Alerts: Optional, allows alarms to bypass Silent Mode and Do Not Disturb")
                    .foregroundColor(.white)

                Text("No account, internet connection, or subscription is required. The app functions completely offline.")
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Privacy")
    }
}

/// Test game view that doesn't schedule a real alarm.
struct TestGameView: View {
    let onDismiss: () -> Void
    @AppStorage("testRequiredKills") private var testRequiredKills: Int = 10

    var body: some View {
        // The test game overlays a close button (top-right) so the user can
        // back out at any time — this is only for the TEST playground, not
        // for a real ringing alarm, which must not be dismissible.
        ZStack(alignment: .topTrailing) {
            GameView(
                alarm: AlarmModel(
                    time: Date(),
                    label: "Test Game",
                    difficulty: .normal,
                    requiredKills: testRequiredKills
                ),
                onComplete: { onDismiss() }
            )

            // Close-out button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .padding(.top, 8)
            .accessibilityLabel("Close test game")
        }
        .statusBarHidden()
    }
}