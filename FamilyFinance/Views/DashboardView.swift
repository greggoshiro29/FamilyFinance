import SwiftUI
import SwiftData

/// The dashboard — flagship screen showing every credit card account with
/// recent purchases and payments, plus month-to-date numbers.
struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 14) {
                        navGrid

                        statCards

                        creditCardsSection

                        recentActivitySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.refresh(context: modelContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            ZStack {
                // Soft glow behind the logo lifts it off the background.
                Image("AlarmPlayLogo")
                    .resizable()
                    .scaledToFit()
                    .blur(radius: 8)
                    .brightness(0.25)
                    .opacity(0.5)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                Image("AlarmPlayLogo")
                    .resizable()
                    .scaledToFit()
            }
            .frame(maxWidth: 340)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

            Text(viewModel.totalBalance.currencyString)
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundColor(.white)

            Text("\(viewModel.overallUtilization.percentString) of credit used")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(viewModel.today, style: .date)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Navigation Grid

    private var navGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavTile(title: "Bills", icon: "calendar", color: .cyan) {
                viewModel.openBills()
            }
            NavTile(title: "Income", icon: "banknote.fill", color: .green) {
                viewModel.openIncome()
            }
            NavTile(title: "Budgets", icon: "chart.bar.xscale", color: .purple) {
                viewModel.openBudgets()
            }
            NavTile(title: "Settings", icon: "gearshape.fill", color: .orange) {
                viewModel.openSettings()
            }
        }
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Spent This Month", value: viewModel.monthSpend.currencyString, color: .orange)
            StatCard(title: "Income This Month", value: viewModel.monthIncomeValue.currencyString, color: .green)
            StatCard(title: "Net This Month", value: viewModel.netThisMonth.currencyString, color: .cyan)
            StatCard(title: "Bills Due \(viewModel.unpaidDueCount)", value: viewModel.unpaidDueAmount.currencyString, color: .red)
        }
    }

    // MARK: - Credit Cards (the flagship)

    private var creditCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Credit Cards")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    viewModel.beginAddAccount()
                } label: {
                    Label("Add Card", systemImage: "plus.circle.fill")
                        .foregroundColor(.cyan)
                }
                .buttonStyle(.borderless)
            }

            if viewModel.accountSummaries.isEmpty {
                emptyAccountsState
            } else {
                ForEach(viewModel.accountSummaries) { summary in
                    CreditCardAccountCard(summary: summary)
                }
            }
        }
    }

    private var emptyAccountsState: some View {
        VStack(spacing: 14) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.cyan.opacity(0.5))

            Text("No credit cards yet")
                .font(.title3)
                .foregroundColor(.white)

            Text("Tap Add Card to link your first account and see purchases and payments here.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(viewModel.recentActivity) { tx in
                TxRow(tx: tx)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.beginEditTransaction(tx)
                    }
            }

            addTransactionButton
        }
    }

    private var addTransactionButton: some View {
        Button {
            viewModel.beginAddTransactionGeneric()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Transaction")
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
}

// MARK: - Nav Tile

private struct NavTile: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
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

// MARK: - Credit Card Account Card

private struct CreditCardAccountCard: View {
    let summary: AccountSummary
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let account = summary.account
        let accent = account.color.color
        let utilization = account.utilization > 100.0 ? 1.0 : account.utilization / 100.0

        VStack(spacing: 10) {
            // Header
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
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                        .frame(width: 8 + 240.0 * utilization, height: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: 8)

                Text("\(account.utilization.percentString) of \(account.creditLimit.currencyString) limit")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: true, vertical: false)
            }

            // Recent activity
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent purchases")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))

                if summary.purchases.isEmpty {
                    Text("No purchases yet")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    ForEach(summary.purchases) { tx in
                        TxRow(tx: tx)
                    }
                }

                if !summary.payments.isEmpty {
                    Text("Recent payments")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    ForEach(summary.payments) { tx in
                        TxRow(tx: tx)
                    }
                }
            }

            // Quick actions
            HStack(spacing: 8) {
                QuickActionButton(title: "+ Purchase", color: .orange) {
                    viewModel.beginAddTransaction(for: account)
                }
                QuickActionButton(title: "+ Payment", color: .green) {
                    viewModel.beginAddTransaction(for: account)
                }
                QuickActionButton(title: "Edit", color: accent) {
                    viewModel.beginEditAccount(account)
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
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.openAccountDetail(account)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(account.issuer) balance \(account.balance.currencyString), limit \(account.creditLimit.currencyString)")
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
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

// MARK: - Transaction Row

struct TxRow: View {
    let tx: CardTransaction

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: tx.kind.systemImage)
                .font(.caption)
                .foregroundColor(tx.kind.color)

            VStack(alignment: .leading, spacing: 1) {
                Text(tx.merchant)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text("\(tx.date.shortDateLabel) • \(tx.category.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Text(tx.amount.signedCurrencyString)
                .font(.body)
                .foregroundColor(tx.kind.color)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}