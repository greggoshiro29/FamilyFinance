import SwiftUI
import SwiftData

/// Add / Edit family member sheet.
struct MemberEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = SettingsViewModel()

    @State private var formVM: MemberEditViewModel
    @State private var confirmDelete = false

    init(member: FamilyMember? = nil) {
        _formVM = State(initialValue: MemberEditViewModel(member: member))
    }

    var body: some View {
        Form {
            Section("Member") {
                TextField("Name", text: $formVM.name)
                Toggle("Primary (household owner)", isOn: $formVM.isPrimary)
                    .tint(.cyan)
            }

            Section("Avatar") {
                HStack {
                    ForEach(formVM.avatarOptions, id: \.self) { emoji in
                        Button {
                            formVM.avatarEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(
                                    formVM.avatarEmoji == emoji
                                        ? Color.cyan.opacity(0.25)
                                        : Color.clear
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            formVM.avatarEmoji == emoji
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

            if formVM.isEditing {
                Section {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Member", systemImage: "trash")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.05, green: 0.05, blue: 0.15))
        .preferredColorScheme(.dark)
        .navigationTitle(formVM.isEditing ? "Edit Member" : "Add Member")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let member = formVM.buildMember() {
                        vm.saveMember(member, context: modelContext)
                        dismiss()
                    }
                }
                .fontWeight(.bold)
            }
        }
        .confirmationDialog("Delete this member?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Member", role: .destructive) {
                vm.deleteMember(formVM.member, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Credit cards keep their cardholder name text.")
        }
    }
}