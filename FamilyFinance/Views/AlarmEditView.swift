import SwiftUI

/// Add / Edit alarm configuration screen.
struct AlarmEditView: View {
    @Environment(AlarmListViewModel.self) private var listVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var vm: AlarmEditViewModel

    init(alarm: AlarmModel? = nil) {
        _vm = State(initialValue: AlarmEditViewModel(alarm: alarm))
    }

    var body: some View {
        Form {
            // Time
            Section("Time") {
                HStack {
                    Picker("Hour", selection: $vm.selectedHour) {
                        ForEach(1...12, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text(":")
                        .font(.title)
                        .foregroundColor(.cyan)

                    Picker("Minute", selection: $vm.selectedMinute) {
                        ForEach(vm.minutes, id: \.self) { min in
                            Text(String(format: "%02d", min)).tag(min)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("AM/PM", selection: $vm.isPM) {
                        Text("AM").tag(false)
                        Text("PM").tag(true)
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }
                .frame(height: 150)
            }

            // Label
            Section("Label") {
                TextField("Alarm label", text: $vm.label)
            }

            // Repeat
            Section("Repeat") {
                Picker("Repeat", selection: $vm.repeatSchedule) {
                    ForEach(vm.repeatOptions, id: \.displayName) { option in
                        Text(option.displayName).tag(option)
                    }
                }

                if case .custom = vm.repeatSchedule {
                    HStack {
                        ForEach(1...7, id: \.self) { day in
                            Button {
                                if vm.customDays.contains(day) {
                                    vm.customDays.remove(day)
                                } else {
                                    vm.customDays.insert(day)
                                }
                            } label: {
                                Text(Calendar.shortDayNames[day - 1])
                                    .font(.caption)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        vm.customDays.contains(day)
                                            ? Color.cyan.opacity(0.3)
                                            : Color.clear
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                vm.customDays.contains(day)
                                                    ? Color.cyan
                                                    : Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Sound
            Section("Sound") {
                Picker("Alarm Sound", selection: $vm.selectedSound) {
                    ForEach(vm.soundOptions, id: \.rawValue) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }

                Button {
                    vm.previewSound()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Preview Sound")
                    }
                    .foregroundColor(.cyan)
                }
            }

            // Vibration
            Section {
                Toggle("Vibration", isOn: $vm.vibrationEnabled)
                    .tint(.cyan)
            }

            // Challenge
            Section("Challenge") {
                Picker("Difficulty", selection: $vm.difficulty) {
                    ForEach(vm.difficultyOptions, id: \.rawValue) { diff in
                        HStack {
                            Text(diff.rawValue)
                            Spacer()
                            Text(difficultyDescription(diff))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .tag(diff)
                    }
                }

                Stepper("Aliens Required: \(vm.requiredKills)", value: $vm.requiredKills, in: 10...100)
            }

            // Delete section — shown only when editing an existing alarm.
            if vm.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Alarm", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(vm.isEditing ? "Edit Alarm" : "New Alarm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this alarm?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Alarm", role: .destructive) {
                deleteAlarm()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This alarm will be removed and its schedule cancelled.")
        }
    }

    @State private var confirmDelete = false

    private func save() {
        let alarm = vm.buildAlarm()
        listVM.saveAlarm(alarm, context: modelContext)
        dismiss()
    }

    private func deleteAlarm() {
        let alarm = vm.buildAlarm()
        listVM.deleteAlarm(alarm, context: modelContext)
        dismiss()
    }

    private func difficultyDescription(_ diff: Difficulty) -> String {
        switch diff {
        case .easy: return "Large window"
        case .normal: return "Medium window"
        case .hard: return "Small window"
        }
    }
}