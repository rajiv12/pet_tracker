import Foundation
import SwiftUI

class DataStore: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var duties: [PetDuty] = []

    private let petsKey = "saved_pets"
    private let dutiesKey = "saved_duties"

    init() {
        loadPets()
        loadDuties()
    }

    // MARK: - Pet Operations

    func addPet(_ pet: Pet) {
        pets.append(pet)
        savePets()
    }

    func updatePet(_ pet: Pet) {
        if let index = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[index] = pet
            savePets()
        }
    }

    func deletePet(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        duties.removeAll { $0.petId == pet.id }
        savePets()
        saveDuties()
    }

    // MARK: - Duty Operations

    func addDuty(_ duty: PetDuty) {
        duties.append(duty)
        saveDuties()
    }

    func updateDuty(_ duty: PetDuty) {
        if let index = duties.firstIndex(where: { $0.id == duty.id }) {
            duties[index] = duty
            saveDuties()
        }
    }

    func deleteDuty(_ duty: PetDuty) {
        duties.removeAll { $0.id == duty.id }
        saveDuties()
    }

    func toggleDutyCompletion(_ duty: PetDuty) {
        if let index = duties.firstIndex(where: { $0.id == duty.id }) {
            duties[index].isCompleted.toggle()
            duties[index].completedDate = duties[index].isCompleted ? Date() : nil

            if duties[index].isCompleted && duties[index].isRecurring,
               let interval = duties[index].recurrenceInterval {
                let nextDuty = createNextRecurrence(from: duties[index], interval: interval)
                duties.append(nextDuty)
            }
            saveDuties()
        }
    }

    func dutiesForPet(_ pet: Pet) -> [PetDuty] {
        duties.filter { $0.petId == pet.id }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func pendingDutiesForPet(_ pet: Pet) -> [PetDuty] {
        dutiesForPet(pet).filter { !$0.isCompleted }
    }

    var todaysDuties: [PetDuty] {
        duties.filter { $0.isDueToday && !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var overdueDuties: [PetDuty] {
        duties.filter { $0.isOverdue }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var upcomingDuties: [PetDuty] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return duties.filter { !$0.isCompleted && $0.dueDate >= tomorrow && $0.dueDate <= weekFromNow }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func petForDuty(_ duty: PetDuty) -> Pet? {
        pets.first { $0.id == duty.petId }
    }

    // MARK: - Private Helpers

    private func createNextRecurrence(from duty: PetDuty, interval: RecurrenceInterval) -> PetDuty {
        let nextDate: Date
        switch interval {
        case .daily:
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: duty.dueDate)!
        case .everyOtherDay:
            nextDate = Calendar.current.date(byAdding: .day, value: 2, to: duty.dueDate)!
        case .weekly:
            nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: duty.dueDate)!
        case .biweekly:
            nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: duty.dueDate)!
        case .monthly:
            nextDate = Calendar.current.date(byAdding: .month, value: 1, to: duty.dueDate)!
        case .yearly:
            nextDate = Calendar.current.date(byAdding: .year, value: 1, to: duty.dueDate)!
        }

        return PetDuty(
            petId: duty.petId,
            category: duty.category,
            title: duty.title,
            notes: duty.notes,
            dueDate: nextDate,
            isRecurring: true,
            recurrenceInterval: interval
        )
    }

    // MARK: - Persistence

    private func savePets() {
        if let data = try? JSONEncoder().encode(pets) {
            UserDefaults.standard.set(data, forKey: petsKey)
        }
    }

    private func loadPets() {
        if let data = UserDefaults.standard.data(forKey: petsKey),
           let decoded = try? JSONDecoder().decode([Pet].self, from: data) {
            pets = decoded
        }
    }

    private func saveDuties() {
        if let data = try? JSONEncoder().encode(duties) {
            UserDefaults.standard.set(data, forKey: dutiesKey)
        }
    }

    private func loadDuties() {
        if let data = UserDefaults.standard.data(forKey: dutiesKey),
           let decoded = try? JSONDecoder().decode([PetDuty].self, from: data) {
            duties = decoded
        }
    }
}
