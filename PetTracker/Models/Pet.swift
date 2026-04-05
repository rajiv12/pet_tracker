import Foundation

enum PetType: String, Codable, CaseIterable, Identifiable {
    case dog = "Dog"
    case cat = "Cat"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        }
    }

    var availableDutyCategories: [DutyCategory] {
        switch self {
        case .dog:
            return [.feeding, .walking, .grooming, .vetVisit, .medication, .training, .other]
        case .cat:
            return [.feeding, .litterBox, .grooming, .vetVisit, .medication, .playtime, .other]
        }
    }
}

struct Pet: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: PetType
    var breed: String
    var dateOfBirth: Date?
    var weight: Double?
    var notes: String

    init(id: UUID = UUID(), name: String, type: PetType, breed: String = "", dateOfBirth: Date? = nil, weight: Double? = nil, notes: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.notes = notes
    }

    var age: String? {
        guard let dob = dateOfBirth else { return nil }
        let components = Calendar.current.dateComponents([.year, .month], from: dob, to: Date())
        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else if let months = components.month {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        return nil
    }
}
