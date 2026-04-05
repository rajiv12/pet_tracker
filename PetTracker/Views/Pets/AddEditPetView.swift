import SwiftUI

struct AddEditPetView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    var existingPet: Pet?

    @State private var name: String = ""
    @State private var type: PetType = .dog
    @State private var breed: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var hasDateOfBirth: Bool = false
    @State private var weight: String = ""
    @State private var notes: String = ""

    var isEditing: Bool { existingPet != nil }

    var body: some View {
        Form {
            Section {
                HStack {
                    ForEach(PetType.allCases) { petType in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                type = petType
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(type == petType ? .indigo : Color(.systemGray5))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: petType.icon)
                                        .font(.title)
                                        .foregroundStyle(type == petType ? .white : .secondary)
                                }
                                Text(petType.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(type == petType ? .indigo : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Pet Type")
            }

            Section {
                TextField("Pet Name", text: $name)
                    .textContentType(.name)
                TextField("Breed (optional)", text: $breed)
            } header: {
                Text("Basic Info")
            }

            Section {
                Toggle("Date of Birth", isOn: $hasDateOfBirth.animation())
                if hasDateOfBirth {
                    DatePicker("Birthday", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                }
                HStack {
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    Text("lbs")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Details")
            }

            Section {
                TextField("Any special notes...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle(isEditing ? "Edit Pet" : "Add Pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    savePet()
                }
                .bold()
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let pet = existingPet {
                name = pet.name
                type = pet.type
                breed = pet.breed
                if let dob = pet.dateOfBirth {
                    dateOfBirth = dob
                    hasDateOfBirth = true
                }
                if let w = pet.weight {
                    weight = String(format: "%.1f", w)
                }
                notes = pet.notes
            }
        }
    }

    private func savePet() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let pet = Pet(
            id: existingPet?.id ?? UUID(),
            name: trimmedName,
            type: type,
            breed: breed.trimmingCharacters(in: .whitespaces),
            dateOfBirth: hasDateOfBirth ? dateOfBirth : nil,
            weight: Double(weight),
            notes: notes.trimmingCharacters(in: .whitespaces)
        )

        if isEditing {
            store.updatePet(pet)
        } else {
            store.addPet(pet)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddEditPetView()
            .environmentObject(DataStore())
    }
}
