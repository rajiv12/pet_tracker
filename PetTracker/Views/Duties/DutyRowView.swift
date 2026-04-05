import SwiftUI

struct DutyRowView: View {
    @EnvironmentObject var store: DataStore
    let duty: PetDuty
    let petId: UUID

    @State private var showingEditDuty = false
    @State private var showingDeleteConfirmation = false

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
            .buttonStyle(.plain)

            Image(systemName: duty.category.icon)
                .font(.body)
                .foregroundStyle(categoryColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(duty.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(duty.isCompleted)
                    .foregroundStyle(duty.isCompleted ? .secondary : .primary)

                HStack(spacing: 6) {
                    Text(duty.dueDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(duty.isOverdue ? .red : .secondary)

                    if duty.isRecurring {
                        Label(duty.recurrenceInterval?.rawValue ?? "Recurring", systemImage: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if duty.isOverdue {
                Text("!")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(.red, in: Circle())
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .contextMenu {
            Button {
                showingEditDuty = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditDuty) {
            NavigationStack {
                AddEditDutyView(petId: petId, existingDuty: duty)
            }
        }
        .confirmationDialog("Delete this duty?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    store.deleteDuty(duty)
                }
            }
        }
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
    DutyRowView(
        duty: PetDuty(petId: UUID(), category: .feeding, title: "Morning meal"),
        petId: UUID()
    )
    .environmentObject(DataStore())
    .padding()
}
