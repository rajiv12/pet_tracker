import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if store.pets.isEmpty {
                        emptyState
                    } else {
                        if !store.overdueDuties.isEmpty {
                            dutySection(title: "Overdue", duties: store.overdueDuties, tint: .red)
                        }

                        if !store.todaysDuties.isEmpty {
                            dutySection(title: "Today", duties: store.todaysDuties, tint: .indigo)
                        }

                        if !store.upcomingDuties.isEmpty {
                            dutySection(title: "Upcoming", duties: store.upcomingDuties, tint: .secondary)
                        }

                        if store.overdueDuties.isEmpty && store.todaysDuties.isEmpty && store.upcomingDuties.isEmpty {
                            allCaughtUp
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .background(Color(.systemGroupedBackground))
        }
    }

    private func dutySection(title: String, duties: [PetDuty], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(tint)

            ForEach(duties) { duty in
                DutyCardView(duty: duty, petName: store.petForDuty(duty)?.name ?? "Unknown")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("Welcome to PetTracker!")
                .font(.title2.bold())
            Text("Add your first pet to get started.")
                .foregroundStyle(.secondary)
            NavigationLink {
                AddEditPetView()
            } label: {
                Label("Add a Pet", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var allCaughtUp: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("All caught up!")
                .font(.title2.bold())
            Text("No tasks due today. Enjoy your time with your pets!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

struct DutyCardView: View {
    @EnvironmentObject var store: DataStore
    let duty: PetDuty
    let petName: String

    var body: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    store.toggleDutyCompletion(duty)
                }
            } label: {
                Image(systemName: duty.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(duty.isCompleted ? .green : .secondary)
            }

            Image(systemName: duty.category.icon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(duty.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(duty.isCompleted)

                HStack(spacing: 6) {
                    Text(petName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if duty.isOverdue {
                        Text("Overdue")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    }

                    if duty.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(duty.dueDate, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var categoryColor: Color {
        switch duty.category.color {
        case "orange": return .orange
        case "green": return .green
        case "brown": return .brown
        case "pink": return .pink
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(DataStore())
}
