import SwiftUI

struct PetDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    let pet: Pet

    @State private var showingEditPet = false
    @State private var showingAddDuty = false
    @State private var showingDeleteConfirmation = false
    @State private var filterCompleted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                petHeader
                statsBar
                dutiesSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditPet = true
                    } label: {
                        Label("Edit Pet", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Pet", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditPet) {
            NavigationStack {
                AddEditPetView(existingPet: pet)
            }
        }
        .sheet(isPresented: $showingAddDuty) {
            NavigationStack {
                AddEditDutyView(petId: pet.id)
            }
        }
        .confirmationDialog("Delete \(pet.name)?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deletePet(pet)
                dismiss()
            }
        } message: {
            Text("This will also remove all duties for \(pet.name). This cannot be undone.")
        }
    }

    private var petHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(pet.type == .dog ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: pet.type.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(pet.type == .dog ? .blue : .orange)
            }

            VStack(spacing: 4) {
                Text(pet.name)
                    .font(.title2.bold())

                HStack(spacing: 8) {
                    if !pet.breed.isEmpty {
                        Text(pet.breed)
                    }
                    if let age = pet.age {
                        if !pet.breed.isEmpty { Text("·") }
                        Text(age)
                    }
                    if let weight = pet.weight {
                        Text("·")
                        Text(String(format: "%.1f lbs", weight))
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            if !pet.notes.isEmpty {
                Text(pet.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statsBar: some View {
        let allDuties = store.dutiesForPet(pet)
        let pending = allDuties.filter { !$0.isCompleted }
        let overdue = allDuties.filter { $0.isOverdue }
        let completed = allDuties.filter { $0.isCompleted }

        return HStack(spacing: 0) {
            statItem(count: pending.count, label: "Pending", color: .indigo)
            Divider().frame(height: 32)
            statItem(count: overdue.count, label: "Overdue", color: .red)
            Divider().frame(height: 32)
            statItem(count: completed.count, label: "Done", color: .green)
        }
        .padding(.vertical, 12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var dutiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Duties")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation { filterCompleted.toggle() }
                } label: {
                    Text(filterCompleted ? "Show All" : "Hide Done")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                }

                Button {
                    showingAddDuty = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                }
            }

            let duties = filterCompleted
                ? store.dutiesForPet(pet).filter { !$0.isCompleted }
                : store.dutiesForPet(pet)

            if duties.isEmpty {
                VStack(spacing: 8) {
                    Text("No duties yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Tap + to add feeding times, walks, vet visits, and more.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(duties) { duty in
                    DutyRowView(duty: duty, petId: pet.id)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PetDetailView(pet: Pet(name: "Buddy", type: .dog, breed: "Golden Retriever"))
            .environmentObject(DataStore())
    }
}
