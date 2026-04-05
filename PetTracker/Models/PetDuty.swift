import Foundation

enum DutyCategory: String, Codable, CaseIterable, Identifiable {
    case feeding = "Feeding"
    case walking = "Walking"
    case litterBox = "Litter Box"
    case grooming = "Grooming"
    case vetVisit = "Vet Visit"
    case medication = "Medication"
    case training = "Training"
    case playtime = "Playtime"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .walking: return "figure.walk"
        case .litterBox: return "tray.fill"
        case .grooming: return "scissors"
        case .vetVisit: return "cross.case.fill"
        case .medication: return "pill.fill"
        case .training: return "star.fill"
        case .playtime: return "gamecontroller.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .feeding: return "orange"
        case .walking: return "green"
        case .litterBox: return "brown"
        case .grooming: return "pink"
        case .vetVisit: return "red"
        case .medication: return "blue"
        case .training: return "purple"
        case .playtime: return "yellow"
        case .other: return "gray"
        }
    }
}

enum RecurrenceInterval: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case everyOtherDay = "Every Other Day"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }
}

struct PetDuty: Identifiable, Codable {
    var id: UUID
    var petId: UUID
    var category: DutyCategory
    var title: String
    var notes: String
    var dueDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    var isRecurring: Bool
    var recurrenceInterval: RecurrenceInterval?

    init(id: UUID = UUID(), petId: UUID, category: DutyCategory, title: String, notes: String = "", dueDate: Date = Date(), isCompleted: Bool = false, completedDate: Date? = nil, isRecurring: Bool = false, recurrenceInterval: RecurrenceInterval? = nil) {
        self.id = id
        self.petId = petId
        self.category = category
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }
}
