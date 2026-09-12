import SwiftUI
import SwiftData

/// Add / Edit credit account sheet.
struct AccountEditView: View {
    @Environment(DashboardViewModel.self) private var dashboardVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var vm: AccountEditViewModel
    @State private var confirmDelete = false

    init(account: CreditAccount? = nil) {
        _vm = State(initialValue: AccountEditViewModel(account: account))
    }

    var body: some View {
        Form {
            Section("Card") {
                TextField("Card Issuer (e.g. Chase Sapphire)", text: $vm.issuer)
                TextField("Cardholder", text: $vm.holderName)
                TextField("Last 4 Digits", text: $vm.lastFour)
            }

            Section("Balances") {
                TextField("Current Balance", text: $vm.balanceText)
                TextField("Credit Limit", text: $vm.limitText)
            }

            Section("Terms") {
                Stepper("APR: \(vm.apr)%", value: $vm.apr, in: 0...36)
                Stepper("Statement Closes: Day \(vm.statementDay)", value: $vm.statementDay, in: 1...28)
                Stepper("Payment Due: Day \(vm.dueDay)", value: $vm.dueDay, in: 1...28)
            }

            Section("Color") {
                HStack {
                    ForEach(vm.colorOptions, id: \.rawValue) { option in
                        Button {
                            vm.selectedColor = option
                        } label: {
                            Circle()
                                .fill(option.color.opacity(vm.selectedColor == option ? 0.9 : 0.35))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(vm.selectedColor == option ? option.color : Color.white.opacity(0.15), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.rawValue)
                    }
                }
                .padding(.vertical, 4)
            }

            // Delete section — shown only when editing an existing account.
            if vm.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Card", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(vm.isEditing ? "Edit Card" : "Add Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let account = vm.buildAccount() {
                        dashboardVM.saveAccount(account, context: modelContext)
                        dismiss()
                    }
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this card?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Card", role: .destructive) {
                dashboardVM.deleteAccount(vm.account, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The card and all its transactions will be removed.")
        }
    }
}