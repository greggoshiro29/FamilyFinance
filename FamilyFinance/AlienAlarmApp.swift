import SwiftUI
import SwiftData
import UserNotifications

@main
struct AlienAlarmApp: App {
    @State private var listVM = AlarmListViewModel()
    private let notificationDelegate = NotificationDelegate()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([AlarmModel.self, AlarmOccurrence.self])
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
                .environment(listVM)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    AlarmScheduler.shared.registerNotificationCategories()
                    setupNotificationDelegate()
                }
        }
    }

    /// Wire the notification delegate so fired alarms present in the app and
    /// launch the active-alarm challenge (game).
    private func setupNotificationDelegate() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        let container = sharedModelContainer
        notificationDelegate.onAlarmFired = { [weak listVM] alarmIDString in
            guard let listVM = listVM else { return }
            let context = container.mainContext
            guard let uuidString = alarmIDString, let uuid = UUID(uuidString: uuidString) else {
                // No alarm id -> still surface the challenge UI generically.
                listVM.showActiveAlarmWithAnyAlarm(context: context)
                return
            }
            listVM.handleAlarmFired(uuid: uuid, context: context)
        }
    }
}

struct ContentView: View {
    @Environment(AlarmListViewModel.self) private var listVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var vm = listVM

        NavigationStack(path: $vm.navigationPath) {
            AlarmListView()
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "settings":
                        SettingsView()
                    case "statistics":
                        StatisticsView()
                    default:
                        EmptyView()
                    }
                }
        }
        .sheet(isPresented: $vm.showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $vm.showingAddAlarm) {
            NavigationStack {
                AlarmEditView()
            }
        }
        .sheet(item: $vm.editingAlarm) { alarm in
            NavigationStack {
                AlarmEditView(alarm: alarm)
            }
        }
        .fullScreenCover(isPresented: $vm.showActiveAlarm) {
            if let alarm = vm.activeAlarm {
                ActiveAlarmView(alarm: alarm)
            }
        }
        .statusBarHidden()
    }
}