import SwiftUI
import SwiftData

/// Add / Edit income entry sheet.
struct IncomeEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = IncomeViewModel()

    @State private var formVM: IncomeEditViewModel
    @State private var confirmDelete = false

    init(entry: IncomeEntry? = nil) {
        _formVM = State(initialValue: IncomeEditViewModel(entry: entry))
    }

    var body: some View {
        Form {
            Section("Income") {
                TextField("Source (e.g. Paycheck, Side Gig)", text: $formVM.source)
                TextField("Member (optional)", text: $formVM.memberName)
                TextField("Amount", text: $formVM.amountText)
            }

            Section("Schedule") {
                Picker("Frequency", selection: $formVM.frequency) {
                    ForEach(formVM.frequencyOptions, id: \.rawValue) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
            }

            Section("Date") {
                HStack {
                    Picker("Day", selection: $formVM.day) {
                        ForEach(formVM.days, id: \.self) { day in
                            Text("\\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 120)

                    Picker("Month", selection: $formVM.month) {
                        ForEach(formVM.months, id: \.self) { month in
                            Text(Calendar.monthNames[month - 1].prefix(3)).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 120)

                    Picker("Year", selection: $formVM.year) {
                        ForEach(formVM.years, id: \.self) { year in
                            Text("\\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, maxHeight: 120)
                }
                .frame(height: 120)
            }

            if formVM.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Income", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(formVM.isEditing ? "Edit Income" : "Add Income")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let entry = formVM.buildEntry() {
                        vm.saveIncome(entry, context: modelContext)
                        dismiss()
                    }
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this income?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Income", role: .destructive) {
                vm.deleteIncome(formVM.entry, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}