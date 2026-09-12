import SwiftUI
import SwiftData

/// App settings: household, family members, bill reminders, about, reset.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = SettingsViewModel()
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]
    @Query(sort: \Bill.createdAt) private var bills: [Bill]

    var body: some View {
        Form {
            // Household
            Section("Household") {
                TextField("Household Name", text: $vm.householdName)

                Picker("Currency", selection: $vm.currencySymbol) {
                    ForEach(vm.currencyOptions, id: \.self) { symbol in
                        Text(symbol).tag(symbol)
                    }
                }
            }

            // Family Members
            Section("Family Members") {
                ForEach(members) { member in
                    HStack {
                        Text("\\(member.avatarEmoji)  \\(member.name)")
                            .font(.body)
                            .foregroundColor(.white)

                        if member.isPrimary {
                            Text("Primary")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Button {
                            vm.beginEditMember(member)
                        } label: {
                            Image(systemName: "pencil")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit \\(member.name)")

                        Button {
                            vm.deleteMember(member, context: modelContext)
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete \\(member.name)")
                    }
                }

                Button {
                    vm.beginAddMember()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Member")
                    }
                    .foregroundColor(.cyan)
                }
            }

            // Bill Reminders
            Section("Bill Reminders") {
                Toggle("Reminder Notifications", isOn: $vm.remindersEnabled)
                    .tint(.cyan)

                Stepper("Remind \\(vm.defaultReminderDays) day(s) before due",
                        value: $vm.defaultReminderDays, in: 0...10)

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

                Button {
                    if let bill = bills.first {
                        Task {
                            BillReminderScheduler.shared.scheduleDemoReminder(bill)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Send Test Reminder")
                    }
                    .foregroundColor(.cyan)
                }

                Button("Open System Settings") {
                    vm.openSystemSettings()
                }
                .foregroundColor(.cyan)
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
                Button("Reset Demo Data") {
                    vm.resetDemoData(context: modelContext)
                }
                .foregroundColor(.orange)
            } footer: {
                Text("Wipes all accounts, transactions, bills, and income. A fresh demo household is recreated on next launch.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.loadMembers(context: modelContext)
            Task { await vm.refreshPermissionStatus() }
        }
        .sheet(isPresented: $vm.showingAddMember) {
            NavigationStack {
                MemberEditView()
            }
        }
        .sheet(item: $vm.editingMember) { member in
            NavigationStack {
                MemberEditView(member: member)
            }
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

                Text("FamilyFinance stores all data locally on your device. No account information, balances, or transactions are collected, transmitted, or shared with any third party.")
                    .foregroundColor(.white)

                Text("Data Stored Locally:")
                    .fontWeight(.semibold)

                Text("• Credit card accounts (issuer, last four digits, balance, credit limit)\\n• Card transactions (merchant, amount, date, category)\\n• Bills and payment history\\n• Income entries and household member names\\n• Budget limits")
                    .foregroundColor(.white)

                Text("Permissions:")
                    .fontWeight(.semibold)

                Text("• Notifications: Optional, used only to remind you when bills are due")

                Text("No account, internet connection, or subscription is required. The app functions completely offline.")
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Privacy")
    }
}