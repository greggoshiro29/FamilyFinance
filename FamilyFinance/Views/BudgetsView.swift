import SwiftUI
import SwiftData

/// Category budgets: spent vs limit with progress bars.
struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = BudgetsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Total Budgeted", value: vm.totalLimit.currencyString, color: .purple)
                    StatCard(title: "Spent So Far", value: vm.totalSpent.currencyString, color: .orange)
                }

                if vm.statuses.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\\(vm.totalRemaining.currencyString) left to spend")
                            .font(.subheadline)
                            .foregroundColor(vm.totalRemaining < 0 ? .red : .white.opacity(0.8))

                        ForEach(vm.statuses) { status in
                            BudgetCard(status: status, onEdit: { vm.editingBudget = status.budget })
                        }
                    }

                    addBudgetButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.refresh(context: modelContext)
        }
        .sheet(isPresented: $vm.showingAddBudget) {
            NavigationStack {
                BudgetEditView()
            }
        }
        .sheet(item: $vm.editingBudget) { budget in
            NavigationStack {
                BudgetEditView(budget: budget)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.editingBudget = nil
                    vm.showingAddBudget = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    private var addBudgetButton: some View {
        Button {
            vm.editingBudget = nil
            vm.showingAddBudget = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Budget")
                    .font(.title3)
            }
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 30)
            Image(systemName: "chart.bar.xscale")
                .font(.system(size: 52))
                .foregroundColor(.purple.opacity(0.5))

            Text("No budgets yet")
                .font(.title3)
                .foregroundColor(.white)

            Text("Set monthly limits per category and track spending from your credit cards.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            addBudgetButton
        }
    }
}

// MARK: - Budget Card

private struct BudgetCard: View {
    let status: BudgetStatus
    let onEdit: () -> Void

    var body: some View {
        let category = status.budget.category
        let accent = category.color
        let over = status.spent > status.budget.monthlyLimit
        let ratio = status.ratio > 100.0 ? 1.0 : status.ratio / 100.0

        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: category.systemImage)
                    .font(.title3)
                    .foregroundColor(accent)

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.rawValue)
                        .font(.body)
                        .foregroundColor(.white)

                    Text("\\(status.spent.currencyString) of \\(status.budget.monthlyLimit.currencyString)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Text(status.ratio.percentString)
                    .font(.body)
                    .foregroundColor(over ? .red : accent)
            }

            ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(over ? .red : accent)
                    .frame(width: 8 + 260.0 * ratio, height: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: 6)

            Text(over
                ? "\\((-status.remaining).currencyString) over budget"
                : "\\(status.remaining.currencyString) left")
                .font(.caption2)
                .foregroundColor(over ? .red : .white.opacity(0.6))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\\(category.rawValue) budget \\(status.spent.currencyString) of \\(status.budget.monthlyLimit.currencyString)")
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}