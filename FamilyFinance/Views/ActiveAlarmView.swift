import SwiftUI

/// Full-screen active alarm interface when alarm fires.
struct ActiveAlarmView: View {
    @Environment(AlarmListViewModel.self) private var listVM
    let alarm: AlarmModel

    @State private var showGame = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Alarm icon with pulse animation
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.15
                        }
                    }

                // Time
                Text(alarm.formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                // Label
                Text(alarm.label)
                    .font(.title2)
                    .foregroundColor(.white)

                // Challenge message
                VStack(spacing: 8) {
                    Text("🚀 WAKE-UP MISSION 🚀")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text("Destroy \(alarm.requiredKills) aliens to stop the alarm")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )

                Spacer()

                // Start mission button
                Button {
                    showGame = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("START WAKE-UP MISSION")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cyan)
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .accessibilityLabel("Start wake-up mission. Destroy \(alarm.requiredKills) aliens to stop the alarm.")
                .accessibilityHint("Opens the shooting game.")
            }
        }
        .onAppear {
            // Start alarm audio and haptics
            AudioManager.shared.startAlarm(sound: alarm.sound)
            HapticManager.shared.alarmActivated()
            AlarmScheduler.shared.alarmFired(alarm)
        }
        .fullScreenCover(isPresented: $showGame) {
            GameView(alarm: alarm) {
                // On completion
                listVM.dismissActiveAlarm()
                showGame = false
                listVM.showActiveAlarm = false
            }
        }
    }
}