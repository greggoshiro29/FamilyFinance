# AlarmPlay: Alien Invasion — iOS App

**The Alarm Clock That Fights Back**

AlarmPlay: Alien Invasion is a daily alarm clock that requires the user to complete a one-button space-shooter challenge before the alarm is dismissed. Destroy a target number of aliens (default 15) to prove you're awake.

Built with Swift 6.3, SwiftUI, and SwiftData. Targets iPhone running iOS 26+.

## Project Structure

```
AlienAlarm/
├── AlienAlarm.xcodeproj/
├── AlienAlarm/
│   ├── AlienAlarmApp.swift          # App entry point
│   ├── Info.plist                   # App configuration
│   ├── Assets.xcassets/             # Asset catalog
│   ├── Models/
│   │   ├── AlarmModel.swift         # SwiftData alarm model
│   │   ├── AlarmOccurrence.swift    # SwiftData occurrence/history model
│   │   └── GameState.swift          # Game state structures (in-memory)
│   ├── ViewModels/
│   │   ├── AlarmListViewModel.swift  # Main list screen logic
│   │   ├── AlarmEditViewModel.swift  # Add/edit alarm logic
│   │   ├── SettingsViewModel.swift   # Settings screen logic
│   │   └── StatisticsViewModel.swift # History/stats screen logic
│   ├── Views/
│   │   ├── AlarmListView.swift      # Main alarm clock screen
│   │   ├── AlarmEditView.swift      # Add/edit alarm form
│   │   ├── ActiveAlarmView.swift    # Full-screen alarm trigger
│   │   ├── GameView.swift           # One-button space shooter
│   │   ├── CompletionView.swift     # Mission complete/results screen
│   │   ├── SettingsView.swift       # App settings
│   │   ├── StatisticsView.swift     # Wake-up history
│   │   └── OnboardingView.swift     # First-launch flow
│   ├── Services/
│   │   ├── AlarmScheduler.swift     # AlarmKit + notification scheduling
│   │   ├── AudioManager.swift       # Synthesized alarm sounds + SFX
│   │   ├── HapticManager.swift      # Haptic feedback
│   │   └── PermissionManager.swift  # Notification permissions
│   ├── Game/
│   │   ├── GameEngine.swift         # Core game logic
│   │   ├── AlienSprite.swift        # Procedural alien designs
│   │   ├── StarField.swift          # Animated space background
│   │   └── TargetingReticle.swift   # HUD reticle
│   └── Utilities/
│       ├── Constants.swift          # App constants, enums
│       └── DateExtensions.swift     # Date formatting helpers
├── AlienAlarmTests/                 # Unit tests
└── AlienAlarmUITests/               # UI tests (stub)
```

## Setup Instructions

### Prerequisites

- Xcode 26.0 or later
- iOS 26.0+ Simulator or physical iPhone
- macOS 26+

### Build & Run

1. Open `AlienAlarm.xcodeproj` in Xcode
2. Select the "AlienAlarm" scheme
3. Choose a destination: iPhone 16 Simulator (or any iOS 26+ device)
4. Press Cmd+R to build and run

Or from the command line:

```bash
cd AlienAlarm
xcodebuild -project AlienAlarm.xcodeproj \
  -scheme AlienAlarm \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

### Running Tests

```bash
xcodebuild -project AlienAlarm.xcodeproj \
  -scheme AlienAlarm \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Note: A test target needs to be added to the Xcode project to run tests via Xcode. The test files at `AlienAlarmTests/` contain the test cases ready for integration.

## Required Capabilities & Permissions

- **Notifications** (`UNAuthorizationOptions`: `.alert`, `.sound`, `.badge`, `.criticalAlert`)
- **Critical Alerts** — allows alarms to bypass Silent Mode and Do Not Disturb

No background modes, no internet access, no account setup required.

## App Flow

### Normal Alarm Flow

1. User sets an alarm with time, repeat schedule, sound, difficulty, and required kills
2. AlarmScheduler registers the alarm with AlarmKit (iOS 26+) or UNNotification fallback
3. At alarm time, a notification fires
4. User opens the app → sees ActiveAlarmView (full screen, alarm sound playing)
5. User taps "START WAKE-UP MISSION" → GameView opens
6. User destroys aliens by pressing FIRE when they overlap the targeting reticle
7. After destroying all required aliens (default: 15), mission complete
8. Alarm sound stops, statistics are saved, user returns to alarm list

### Emergency Exit Flow

1. During gameplay, a small "Emergency Exit" link is available (if enabled in Settings)
2. User must press and hold for 5 seconds
3. Confirmation dialog appears warning the alarm will be dismissed
4. On confirmation: alarm stops, occurrence saved as "Emergency Dismissed"

## Known iOS Limitations

This app cannot do everything Apple's built-in Clock app can because of platform restrictions:

| Limitation | Explanation |
|---|---|
| **Background alarm firing** | Third-party apps cannot wake the device from a powered-off state or play alarm audio in the background indefinitely. Notifications fire but may be delayed if the device is in low-power mode. |
| **Force-quit recovery** | If the user force-quits the app during an alarm challenge, the challenge state is saved to UserDefaults, but the alarm audio stops. The next launch will restore the challenge if incomplete. |
| **Silent Mode bypass** | Critical Alerts capability is required and must be enabled by the user in Settings. Without it, the alarm notification may be silenced. |
| **Device restart** | Scheduled notifications survive device restarts, but AlarmKit scheduling may need re-registration on next launch. |
| **Screen always-on** | The app cannot keep the screen on indefinitely like Apple's Clock. iOS may dim the screen after the idle timer fires. |
| **Volume control** | Alarm volume uses the system ringer/alarm volume, not media volume. Users adjust alarm volume via Settings → Sounds & Haptics. |
| **AlarmKit integration** | AlarmKit is referenced but not fully linked — the current build uses UNNotification as the documented fallback. Full AlarmKit integration requires adding the framework and entitlements. |
| **Multiple simultaneous alarms** | Each alarm schedules a separate notification. iOS may coalesce notifications under certain conditions. |

## Design Decisions

### Audio

All alarm sounds and game effects are **procedurally synthesized** using AVAudioEngine — no audio files are bundled. This keeps the app lightweight and ensures all sounds are original works free of copyright concerns.

### Visual Assets

All alien sprites are **procedurally drawn** using SwiftUI Path and Shape primitives. No imported image assets for enemies, backgrounds, or effects. This avoids any copyright concerns with classic arcade games.

### Data Storage

SwiftData for persistent storage (alarms, occurrences). UserDefaults for transient state (active challenge progress, settings). No external databases or servers.

### Architecture

MVVM with SwiftUI's `@Observable` macro. ViewModels are `@MainActor` isolated. Services (AudioManager, HapticManager, AlarmScheduler) are singleton actors.

## App Store Submission Notes

- **Bundle ID**: `com.alienalarm.app`
- **Category**: Utilities / Health & Fitness
- **Age Rating**: 4+ (cartoon space shooter, no realistic violence)
- **Privacy**: No data collected. All data stored locally.
- **Required Entitlements**: Critical Alerts capability (must be requested from Apple)

### Review Notes

- Clearly explain to App Review that the app's alarm audio is procedural/synthesized and uses standard AVAudioSession APIs
- The game challenge is cartoony and not violent — aliens are geometric shapes
- No "background audio" background mode declared — the app follows Apple's guidelines
- Emergency Exit feature ensures users are never "trapped" by the alarm

## Testing Checklist

- [ ] Add alarm with different repeat schedules
- [ ] Edit existing alarm
- [ ] Enable/disable alarm toggle
- [ ] Delete alarm
- [ ] Test alarm firing (set alarm 1-2 minutes in future)
- [ ] Complete wake-up game challenge
- [ ] Test emergency exit
- [ ] Verify statistics screen updates
- [ ] Test settings changes persist across app restart
- [ ] Verify onboarding flow on fresh install
- [ ] Test with Silent Mode enabled
- [ ] Test with Do Not Disturb enabled
- [ ] Test with device locked
- [ ] Test audio interruptions (incoming call while alarm active)
- [ ] Test VoiceOver navigation
- [ ] Test Dynamic Type scaling
- [ ] Test on different iPhone screen sizes