import SwiftUI
import SwiftData

/// Full history for one credit card: every purchase and payment, grouped
/// by month, with per-month totals. Reached by tapping a card on the
/// dashboard (or via the -previewAccount dev launch argument).
struct AccountDetailView: View {
    @Environment(DashboardViewModel.self) private var dashboardVM
    @Environment(\.modelContext) private var modelContext
    @State private var vm = AccountDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let account = vm.account {
                    accountHeader(account: account)
                    accountActivity(account: account)
                } else {
                    noCardState
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .navigationTitle("Card Activity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.refresh(context: modelContext, accountID: dashboardVM.viewingAccountID)
        }
    }

    // MARK: - Header

    private func accountHeader(account: CreditAccount) -> some View {
        let accent = account.color.color
        let ratio = account.utilization > 100.0 ? 1.0 : account.utilization / 100.0

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Text(account.lastFour)
                        .font(.caption)
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.issuer)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(account.maskedNumber) • \(account.holderName)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Text(account.balance.currencyString)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(account.isOverLimit ? .red : accent)
            }

            // Utilization bar
            HStack(spacing: 10) {
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.10))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accent)
                        .frame(width: 8 + 240.0 * ratio, height: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: 8)

                Text("\(account.utilization.percentString) of \(account.creditLimit.currencyString) limit")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: true, vertical: false)
            }

            // Key terms
            LazyVGrid(
                columns: [
                    GridItem(.flexible()), GridItem(.flexible()),
                    GridItem(.flexible()), GridItem(.flexible())
                ],
                spacing: 10
            ) {
                DetailChip(label: "Limit", value: account.creditLimit.currencyString)
                DetailChip(label: "Available", value: account.availableCredit.currencyString)
                DetailChip(label: "APR", value: "\(account.apr.percentString)")
                DetailChip(label: "Due Day", value: "\(account.dueDay)")
            }

            // Actions
            HStack(spacing: 8) {
                AccountActionButton(title: "+ Purchase", color: .orange) {
                    dashboardVM.beginAddTransaction(for: account)
                }
                AccountActionButton(title: "+ Payment", color: .green) {
                    dashboardVM.beginAddTransaction(for: account)
                }
                AccountActionButton(title: "Edit Card", color: accent) {
                    dashboardVM.beginEditAccount(account)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Activity

    private func accountActivity(account: CreditAccount) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .foregroundColor(.white)

            if vm.groups.isEmpty {
                Text("No transactions yet — add a purchase or payment from the dashboard.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                ForEach(vm.groups) { group in
                    MonthSection(group: group, dashboardVM: dashboardVM)
                }
            }
        }
    }

    // MARK: - Empty State

    private var noCardState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "creditcard.fill")
                .font(.system(size: 52))
                .foregroundColor(.cyan.opacity(0.5))

            Text("No card selected")
                .font(.title3)
                .foregroundColor(.white)

            Text("Go back to the dashboard and tap a credit card to see its full history.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Month Section

private struct MonthSection: View {
    let group: MonthGroup
    let dashboardVM: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.label)
                    .font(.title3)
                    .foregroundColor(.white)

                Spacer()

                if !group.purchases.isEmpty {
                    Text("\(group.purchasesTotal.currencyString) charges")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                if !group.payments.isEmpty {
                    Text("\(group.paymentsTotal.currencyString) payments")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            if !group.purchases.isEmpty {
                ForEach(group.purchases) { tx in
                    TxRow(tx: tx)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dashboardVM.beginEditTransaction(tx)
                        }
                }
            }

            if !group.payments.isEmpty {
                ForEach(group.payments) { tx in
                    TxRow(tx: tx)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dashboardVM.beginEditTransaction(tx)
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail Chip

private struct DetailChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Action Button

private struct AccountActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(color)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}