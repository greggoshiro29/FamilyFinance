import SwiftUI
import SwiftData

/// Add / Edit bill sheet.
struct BillEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = BillsViewModel()

    @State private var formVM: BillEditViewModel
    @State private var confirmDelete = false

    init(bill: Bill? = nil) {
        _formVM = State(initialValue: BillEditViewModel(bill: bill))
    }

    var body: some View {
        Form {
            Section("Bill") {
                TextField("Name (e.g. Rent, Internet)", text: $formVM.name)
                TextField("Amount", text: $formVM.amountText)
            }

            Section("Schedule") {
                Stepper("Due: Day \\(formVM.dueDay) of Month", value: $formVM.dueDay, in: 1...Constants.maxDueDay)
                Picker("Category", selection: $formVM.category) {
                    ForEach(formVM.categoryOptions, id: \.rawValue) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                Stepper("Remind \\(formVM.reminderDays) day(s) before", value: $formVM.reminderDays, in: 0...10)
                Toggle("Active", isOn: $formVM.isActive)
                    .tint(.cyan)
            }

            if formVM.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Bill", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(formVM.isEditing ? "Edit Bill" : "Add Bill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let bill = formVM.buildBill() {
                        vm.saveBill(bill, context: modelContext)
                        dismiss()
                    }
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this bill?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Bill", role: .destructive) {
                vm.deleteBill(formVM.bill, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Its payment history will be removed too.")
        }
    }
}