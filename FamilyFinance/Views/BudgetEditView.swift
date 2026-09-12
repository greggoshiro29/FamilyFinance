import SwiftUI
import SwiftData

/// Add / Edit budget sheet.
struct BudgetEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = BudgetsViewModel()

    @State private var formVM: BudgetEditViewModel
    @State private var confirmDelete = false

    init(budget: BudgetCategory? = nil) {
        _formVM = State(initialValue: BudgetEditViewModel(budget: budget))
    }

    var body: some View {
        Form {
            Section("Budget") {
                Picker("Category", selection: $formVM.category) {
                    ForEach(formVM.categoryOptions, id: \.rawValue) { category in
                        HStack {
                            Image(systemName: category.systemImage)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }

                TextField("Monthly Limit", text: $formVM.monthlyLimitText)
            }

            if formVM.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Budget", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(formVM.isEditing ? "Edit Budget" : "Add Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let budget = formVM.buildBudget() {
                        vm.saveBudget(budget, context: modelContext)
                        dismiss()
                    }
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this budget?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Budget", role: .destructive) {
                vm.deleteBudget(formVM.budget, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}