import SwiftUI
import SwiftData

/// Add / Edit transaction sheet (purchase or payment).
struct TransactionEditView: View {
    @Environment(DashboardViewModel.self) private var dashboardVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CreditAccount.createdAt) private var accounts: [CreditAccount]

    @State private var vm: TransactionEditViewModel
    @State private var confirmDelete = false

    init(transaction: CardTransaction? = nil) {
        _vm = State(initialValue: TransactionEditViewModel(transaction: transaction, accounts: []))
    }

    var body: some View {
        Form {
            Section("Type") {
                Picker("Type", selection: $vm.kind) {
                    ForEach(TransactionKind.allCases, id: \.rawValue) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
            }

            Section("Card") {
                Picker("Card", selection: $vm.selectedAccountID) {
                    ForEach(accounts, id: \.id) { account in
                        Text("\\(account.issuer) •••• \\(account.lastFour)")
                            .tag(account.id)
                    }
                }
            }

            Section(vm.kind == .purchase ? "Purchase" : "Payment") {
                TextField("Merchant / Description", text: $vm.merchant)
                TextField("Amount", text: $vm.amountText)

                if vm.kind == .purchase {
                    Picker("Category", selection: $vm.category) {
                        ForEach(vm.categoryOptions, id: \.rawValue) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
            }

            Section("Date") {
                HStack {
                    Picker("Day", selection: $vm.day) {
                        ForEach(vm.days, id: \.self) { day in
                            Text("\\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 120)

                    Picker("Month", selection: $vm.month) {
                        ForEach(vm.months, id: \.self) { month in
                            Text(Calendar.monthNames[month - 1].prefix(3)).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 120)

                    Picker("Year", selection: $vm.year) {
                        ForEach(vm.years, id: \.self) { year in
                            Text("\\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 120)
                }
                .frame(height: 120)
            }

            // Delete section — shown only when editing an existing transaction.
            if vm.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Transaction", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(vm.isEditing ? "Edit Transaction" : "New Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if buildAndSave() {
                        dismiss()
                    }
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this transaction?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Transaction", role: .destructive) {
                dashboardVM.deleteTransaction(vm.transaction, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The account balance will be adjusted back.")
        }
    }

    private func buildAndSave() -> Bool {
        if vm.accounts.isEmpty {
            vm.accounts = accounts
        }
        if let tx = vm.buildTransaction() {
            dashboardVM.saveTransaction(tx, context: modelContext)
            return true
        }
        return false
    }
}