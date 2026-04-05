import SwiftUI

struct PetListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAddPet = false

    var body: some View {
        NavigationStack {
            Group {
                if store.pets.isEmpty {
                    emptyState
                } else {
                    petList
                }
            }
            .navigationTitle("My Pets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddPet) {
                NavigationStack {
                    AddEditPetView()
                }
            }
        }
    }

    private var petList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.pets) { pet in
                    NavigationLink(destination: PetDetailView(pet: pet)) {
                        PetRowView(pet: pet)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("No pets yet")
                .font(.title2.bold())
            Text("Tap + to add your first furry friend!")
                .foregroundStyle(.secondary)
        }
    }
}

struct PetRowView: View {
    @EnvironmentObject var store: DataStore
    let pet: Pet

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(pet.type == .dog ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: pet.type.icon)
                    .font(.title2)
                    .foregroundStyle(pet.type == .dog ? .blue : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(pet.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !pet.breed.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(pet.breed)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let age = pet.age {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(age)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            let pendingCount = store.pendingDutiesForPet(pet).count
            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.indigo, in: Circle())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

#Preview {
    PetListView()
        .environmentObject(DataStore())
}
