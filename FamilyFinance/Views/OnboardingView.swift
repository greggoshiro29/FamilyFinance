import SwiftUI

/// Onboarding flow shown on first launch.
/// Requests notification permissions and explains the app concept.
struct OnboardingView: View {
    @Environment(AlarmListViewModel.self) private var listVM
    @State private var currentPage = 0
    @State private var permissionGranted = false
    @State private var requestingPermission = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.15)
                .ignoresSafeArea()

            VStack {
                // Page content
                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Bottom button
                VStack(spacing: 12) {
                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.cyan)
                                )
                        }
                    } else {
                        Button {
                            requestPermissionsAndFinish()
                        } label: {
                            HStack {
                                if requestingPermission {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text("Enable Notifications & Get Started")
                                    .fontWeight(.semibold)
                            }
                            .font(.title3)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.cyan)
                            )
                        }
                        .disabled(requestingPermission)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private func requestPermissionsAndFinish() {
        requestingPermission = true
        Task {
            let granted = await PermissionManager.shared.requestNotificationPermission()
            permissionGranted = granted
            listVM.completeOnboarding()
        }
    }

    // MARK: - Pages

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.system(size: 80))
                .foregroundColor(.cyan)

            Text("ALARMPLAY: ALIEN INVASION")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(.cyan)

            Text("The Alarm Clock That Fights Back")
                .font(.title3)
                .foregroundColor(.white)

            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "alarm.fill", text: "Set alarms just like a normal clock")
                FeatureRow(icon: "gamecontroller.fill", text: "Complete a space challenge to dismiss")
                FeatureRow(icon: "bolt.fill", text: "Destroy aliens to prove you're awake")
                FeatureRow(icon: "lock.shield.fill", text: "All data stored locally on your device")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var page2: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎯")
                .font(.system(size: 80))

            Text("How It Works")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer().frame(height: 10)

            VStack(alignment: .leading, spacing: 20) {
                StepRow(number: 1, text: "Your alarm goes off — the sound won't stop until you complete the challenge.")
                StepRow(number: 2, text: "Tap START WAKE-UP MISSION to open the game.")
                StepRow(number: 3, text: "Aliens fly toward a targeting reticle. Press FIRE when they overlap it.")
                StepRow(number: 4, text: "Destroy all required aliens. The alarm stops. You've earned your wake-up!")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var page3: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Notifications Required")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("AlarmPlay: Alien Invasion needs permission to send you notifications when your alarms go off.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Critical Alerts supported — works in Silent Mode")
                        .font(.callout)
                        .foregroundColor(.white)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No data leaves your device")
                        .font(.callout)
                        .foregroundColor(.white)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No internet connection needed")
                        .font(.callout)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.cyan)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                )
            Text(text)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}