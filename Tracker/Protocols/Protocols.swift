import Foundation

protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

protocol ScheduleSelectionDelegate: AnyObject {
    func didSelectSchedule(_ schedule: [Weekday])
}

protocol CreateTrackerViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String)
    func didUpdateTracker(_ tracker: Tracker, categoryTitle: String)
}
