import SwiftUI
import SwiftData

/// First-launch welcome: explains the app and seeds the demo household.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer().frame(height: 20)

                Image("AlarmPlayLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)

                Text("Welcome to FamilyFinance")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Every credit card, bill, paycheck, and budget for the whole household — on one screen. All data stays on this device.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    if !busy {
                        busy = true
                        Task {
                            await viewModel.completeSetup(context: modelContext)
                        }
                        dismiss()
                    }
                } label: {
                    if busy {
                        ProgressView()
                            .padding(.vertical, 14)
                    } else {
                        Text("Get Started")
                            .font(.title3)
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.cyan.opacity(0.15))
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 24)

                Text("A sample family comes pre-loaded so you can explore — every number is editable or deletable.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 20)
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
}