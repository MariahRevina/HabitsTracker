enum FilterType {
    case allTrackers
    case todayTrackers
    case completed
    case notCompleted
    
    var title: String {
        switch self {
        case .allTrackers:
            return "Все трекеры"
        case .todayTrackers:
            return "Трекеры на сегодня"
        case .completed:
            return "Завершённые"
        case .notCompleted:
            return "Незавершённые"
        }
    }
    
    static var allCases: [FilterType] {
        return [.allTrackers, .todayTrackers, .completed, .notCompleted]
    }
}
