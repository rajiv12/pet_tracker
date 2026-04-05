import SwiftUI

struct AddEditDutyView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    let petId: UUID
    var existingDuty: PetDuty?

    @State private var category: DutyCategory = .feeding
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var isRecurring: Bool = false
    @State private var recurrenceInterval: RecurrenceInterval = .daily

    var isEditing: Bool { existingDuty != nil }

    private var pet: Pet? {
        store.pets.first { $0.id == petId }
    }

    private var availableCategories: [DutyCategory] {
        pet?.type.availableDutyCategories ?? DutyCategory.allCases
    }

    var body: some View {
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableCategories) { cat in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    category = cat
                                    if title.isEmpty || DutyCategory.allCases.map(\.rawValue).contains(title) {
                                        title = cat.rawValue
                                    }
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: cat.icon)
                                        .font(.title3)
                                    Text(cat.rawValue)
                                        .font(.caption2)
                                }
                                .frame(width: 72, height: 64)
                                .background(category == cat ? .indigo : Color(.systemGray5))
                                .foregroundStyle(category == cat ? .white : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Category")
            }

            Section {
                TextField("Task name", text: $title)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Details")
            }

            Section {
                DatePicker("Due Date", selection: $dueDate)
            } header: {
                Text("Schedule")
            }

            Section {
                Toggle("Recurring", isOn: $isRecurring.animation())
                if isRecurring {
                    Picker("Repeat", selection: $recurrenceInterval) {
                        ForEach(RecurrenceInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                }
            } header: {
                Text("Recurrence")
            }
        }
        .navigationTitle(isEditing ? "Edit Duty" : "New Duty")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveDuty()
                }
                .bold()
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let duty = existingDuty {
                category = duty.category
                title = duty.title
                notes = duty.notes
                dueDate = duty.dueDate
                isRecurring = duty.isRecurring
                recurrenceInterval = duty.recurrenceInterval ?? .daily
            }
        }
    }

    private func saveDuty() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let duty = PetDuty(
            id: existingDuty?.id ?? UUID(),
            petId: petId,
            category: category,
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate,
            isCompleted: existingDuty?.isCompleted ?? false,
            completedDate: existingDuty?.completedDate,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : nil
        )

        if isEditing {
            store.updateDuty(duty)
        } else {
            store.addDuty(duty)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddEditDutyView(petId: UUID())
            .environmentObject(DataStore())
    }
}
