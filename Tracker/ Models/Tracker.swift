import UIKit

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let shedule: [Weekday]
    let emoji: String
    let isPinned: Bool = false
}
enum Weekday: Int, CaseIterable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var numberValue: Int {
        return self.rawValue
    }
    var name: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
        var shortName: String {
                switch self {
                case .monday: return "Пн"
                case .tuesday: return "Вт"
                case .wednesday: return "Ср"
                case .thursday: return "Чт"
                case .friday: return "Пт"
                case .saturday: return "Сб"
                case .sunday: return "Вс"
                }
        }
}
