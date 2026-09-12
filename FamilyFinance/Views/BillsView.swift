import SwiftUI
import SwiftData

/// Bill payment calendar: month grid with due markers, plus the month's
/// bill list with paid toggles.
struct BillsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = BillsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthNav

                if vm.visibleDueBills.isEmpty {
                    emptyState
                } else {
                    calendarGrid
                    calendarSummary

                    billsList
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Bills")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.refresh(context: modelContext)
        }
        .sheet(isPresented: $vm.showingAddBill) {
            NavigationStack {
                BillEditView()
            }
        }
        .sheet(item: $vm.editingBill) { bill in
            NavigationStack {
                BillEditView(bill: bill)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.editingBill = nil
                    vm.showingAddBill = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    // MARK: - Month Navigation

    private var monthNav: some View {
        HStack(spacing: 14) {
            Button {
                vm.shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            VStack(spacing: 2) {
                Text(vm.month.monthYearLabel)
                    .font(.title2)
                    .foregroundColor(.white)

                Text("\(vm.unpaidCount) unpaid • \(vm.unpaidTotal.currencyString) due")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)

            Button {
                vm.shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
    }

    // MARK: - Calendar

    private var calendarGrid: some View {
        VStack(spacing: 6) {
            HStack {
                ForEach(Calendar.shortWeekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 6
            ) {
                ForEach(0..<42, id: \.self) { i in
                    DayCell(date: vm.monthGrid[i], unpaidKeys: vm.unpaidDayKeys, paidKeys: vm.paidDayKeys, today: Date())
                }
            }
        }
    }

    private var calendarSummary: some View {
        HStack(spacing: 10) {
            LegendDot(color: .orange, label: "\(vm.unpaidCount) unpaid")
            LegendDot(color: .green, label: "paid")
            Spacer()
            Text("\(vm.dueCount) bills this month")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Bill List

    private var billsList: some View {
        List {
            ForEach(vm.visibleDueBills) { due in
                BillRow(
                    due: due,
                    onToggle: { vm.togglePaid(due, context: modelContext) },
                    onEdit: { vm.editingBill = due.bill }
                )
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        vm.deleteBill(due.bill, context: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Section {
                addBillButton
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var addBillButton: some View {
        Button {
            vm.editingBill = nil
            vm.showingAddBill = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Bill")
                    .font(.title3)
            }
            .foregroundColor(.cyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 30)
            Image(systemName: "calendar")
                .font(.system(size: 52))
                .foregroundColor(.cyan.opacity(0.5))

            Text("No bills this month")
                .font(.title3)
                .foregroundColor(.white)

            Text("Add a recurring bill and it will show up on the calendar with a reminder before the due date.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            addBillButton
        }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date?
    let unpaidKeys: Set<String>
    let paidKeys: Set<String>
    let today: Date

    var body: some View {
        if let date = date {
            let isUnpaid = unpaidKeys.contains(date.dayKey)
            let isPaid = paidKeys.contains(date.dayKey)
            let isToday = date.dayKey == today.dayKey
            let busy = isPaid || isUnpaid

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(busy ? Color.white.opacity(0.09) : Color.white.opacity(0.04))
                    .overlay(
                        isToday
                            ? RoundedRectangle(cornerRadius: 10).stroke(Color.cyan, lineWidth: 1.5)
                            : RoundedRectangle(cornerRadius: 10).stroke(busy ? dotColor(busy: isUnpaid).opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
                    )

                VStack(spacing: 3) {
                    Text("\(date.dayOfMonth)")
                        .font(.caption)
                        .foregroundColor(isToday ? .cyan : (busy ? .white : .white.opacity(0.7)))

                    if busy {
                        Circle()
                            .fill(dotColor(busy: isUnpaid))
                            .frame(width: 6, height: 6)
                    } else {
                        Spacer().frame(height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
    }

    private func dotColor(busy: Bool) -> Color {
        busy ? .orange : .green
    }
}

// MARK: - Legend Dot

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Bill Row

private struct BillRow: View {
    let due: DueBill
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(due.isPaid ? .green : .orange)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(due.bill.name)
                    .font(.body)
                    .foregroundColor(.white)

                Text("\(due.dueDate.shortDateLabel) • \(due.bill.category.rawValue)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text(due.bill.amount.currencyString)
                .font(.body)
                .foregroundColor(.white)

            Toggle("", isOn: Binding(
                get: { due.isPaid },
                set: { _ in onToggle() }
            ))
            .tint(.green)
            .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(due.isPaid ? Color.green.opacity(0.25) : Color.orange.opacity(0.25), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(due.bill.name) \(due.bill.amount.currencyString) due \(due.dueDate.shortDateLabel), \(statusLabel)")
    }

    private var statusLabel: String {
        due.isPaid ? "paid" : "unpaid"
    }
}