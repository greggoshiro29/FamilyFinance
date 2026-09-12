import SwiftUI
import SwiftData
import UserNotifications

@main
struct FamilyFinanceApp: App {
    @State private var dashboardVM = DashboardViewModel()
    private let notificationDelegate = NotificationDelegate()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FamilyMember.self,
            CreditAccount.self,
            CardTransaction.self,
            Bill.self,
            BillPayment.self,
            IncomeEntry.self,
            BudgetCategory.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dashboardVM)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    BillReminderScheduler.shared.registerNotificationCategories()
                    setupNotificationDelegate()
                }
        }
    }

    /// Wire the notification delegate so bill reminders route the user to
    /// the Bills screen when they fire.
    private func setupNotificationDelegate() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        let container = sharedModelContainer
        notificationDelegate.onBillReminder = { [weak dashboardVM] billIDString in
            guard let dashboardVM = dashboardVM else { return }
            DispatchQueue.main.async {
                dashboardVM.openBillsFromReminder(billIDString: billIDString)
            }
        }
    }
}

struct ContentView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack(path: $vm.navigationPath) {
            DashboardView()
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "settings":
                        SettingsView()
                    case "bills":
                        BillsView()
                    case "income":
                        IncomeView()
                    case "budgets":
                        BudgetsView()
                    default:
                        EmptyView()
                    }
                }
        }
        .sheet(isPresented: $vm.showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $vm.showingAddAccount) {
            NavigationStack {
                AccountEditView()
            }
        }
        .sheet(item: $vm.editingAccount) { account in
            NavigationStack {
                AccountEditView(account: account)
            }
        }
        .sheet(isPresented: $vm.showingAddTransaction) {
            NavigationStack {
                TransactionEditView()
            }
        }
        .sheet(item: $vm.editingTransaction) { tx in
            NavigationStack {
                TransactionEditView(transaction: tx)
            }
        }
        .statusBarHidden()
    }
}