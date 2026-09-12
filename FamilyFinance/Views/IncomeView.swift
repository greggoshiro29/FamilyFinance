import SwiftUI
import SwiftData

/// Income tracker: this month's totals plus a list of income entries.
struct IncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = IncomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "This Month", value: vm.monthTotal.currencyString, color: .green)
                    StatCard(title: "Past 7 Days", value: vm.weekTotal.currencyString, color: .cyan)
                    StatCard(title: "Recurring Sources", value: vm.recurringTotal.currencyString, color: .purple)
                    StatCard(title: "Entries This Month", value: "\\(vm.sourceCount)", color: .orange)
                }

                incomeSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Income")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.refresh(context: modelContext)
        }
        .sheet(isPresented: $vm.showingAddIncome) {
            NavigationStack {
                IncomeEditView()
            }
        }
        .sheet(item: $vm.editingIncome) { entry in
            NavigationStack {
                IncomeEditView(entry: entry)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.editingIncome = nil
                    vm.showingAddIncome = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Income")
                .font(.headline)
                .foregroundColor(.white)

            if vm.recentEntries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(vm.recentEntries) { entry in
                        IncomeRow(
                            entry: entry,
                            onEdit: { vm.editingIncome = entry }
                        )
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.deleteIncome(entry, context: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    Section {
                        addIncomeButton
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var addIncomeButton: some View {
        Button {
            vm.editingIncome = nil
            vm.showingAddIncome = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Income")
                    .font(.title3)
            }
            .foregroundColor(.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 30)
            Image(systemName: "banknote.fill")
                .font(.system(size: 52))
                .foregroundColor(.green.opacity(0.5))

            Text("No income recorded")
                .font(.title3)
                .foregroundColor(.white)

            Text("Add paychecks and other income to see monthly totals.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            addIncomeButton
        }
    }
}

// MARK: - Income Row

private struct IncomeRow: View {
    let entry: IncomeEntry
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "banknote.fill")
                .font(.body)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.source)
                    .font(.body)
                    .foregroundColor(.white)

                Text("\\(entry.date.shortDateLabel) • \\(entry.frequency.displayName)\\(memberSuffix)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text(entry.amount.currencyString)
                .font(.body)
                .foregroundColor(.green)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .accessibilityElement(children: .contain)
    }

    private var memberSuffix: String {
        entry.memberName != "" ? " • \\(entry.memberName)" : ""
    }
}