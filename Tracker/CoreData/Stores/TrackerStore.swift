import CoreData

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateTrackers()
}

final class TrackerStore: NSObject {
    
    weak var delegate: TrackerStoreDelegate?
    
    private let context: NSManagedObjectContext
    private let trackerCategoryStore: TrackerCategoryStore
    private let colorMarshalling = UIColorMarshalling()
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch {
            LoggerService.shared.error("❌ Failed to fetch trackers: \(error)")
        }
        
        return controller
    }()
    
    init(context: NSManagedObjectContext, trackerCategoryStore: TrackerCategoryStore) {
        self.context = context
        self.trackerCategoryStore = trackerCategoryStore
        super.init()
    }
    
    func createTracker(_ tracker: Tracker, categoryTitle: String) throws {
        
        guard context.persistentStoreCoordinator != nil else {
            throw NSError(domain: "TrackerStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Контекст Core Data не готов"])
        }
        
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.color = UIColorMarshalling.hexString(from: tracker.color)
        trackerCoreData.emoji = tracker.emoji
        
        let scheduleData = try? NSKeyedArchiver.archivedData(withRootObject: tracker.schedule.map { $0.rawValue }, requiringSecureCoding: false)
        trackerCoreData.schedule = scheduleData
        
        let category = try trackerCategoryStore.fetchOrCreateCategory(with: categoryTitle)
        trackerCoreData.category = category
        
        DataBaseStore.shared.saveContext()
    }
    
    func updateTracker(_ tracker: Tracker, categoryTitle: String) throws {
        guard context.persistentStoreCoordinator != nil else {
            throw NSError(domain: "TrackerStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Контекст Core Data не готов"])
        }
        
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        let results = try context.fetch(fetchRequest)
        guard let trackerCoreData = results.first else {
            throw NSError(domain: "TrackerStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "Трекер не найден"])
        }
        
        trackerCoreData.name = tracker.name
        trackerCoreData.color = UIColorMarshalling.hexString(from: tracker.color)
        trackerCoreData.emoji = tracker.emoji
        
        let scheduleData = try? NSKeyedArchiver.archivedData(withRootObject: tracker.schedule.map { $0.rawValue }, requiringSecureCoding: false)
        trackerCoreData.schedule = scheduleData
        
        let category = try trackerCategoryStore.fetchOrCreateCategory(with: categoryTitle)
        trackerCoreData.category = category
        
        DataBaseStore.shared.saveContext()
    }
    func fetchTrackers() -> [Tracker] {
        guard let objects = fetchedResultsController.fetchedObjects else {
            return []
        }
        
        var trackers: [Tracker] = []
        
        for trackerCoreData in objects {
            guard let id = trackerCoreData.id,
                  let name = trackerCoreData.name,
                  let colorHex = trackerCoreData.color,
                  let emoji = trackerCoreData.emoji else {
                continue
            }
            
            var schedule: [Weekday] = []
            if let scheduleData = trackerCoreData.schedule,
               let scheduleArray = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: scheduleData) as? [String] {
                schedule = scheduleArray.compactMap { Weekday(rawValue: $0) }
            }
            
            let color = UIColorMarshalling.color(from: colorHex)
            
            let tracker = Tracker(
                id: id,
                name: name,
                color: color,
                schedule: schedule,
                emoji: emoji
            )
            trackers.append(tracker)
        }
        
        return trackers
    }
    
    func fetchTrackers(for date: Date) -> [TrackerCategory] {
        let calendar = Calendar.current
        let weekdayComponent = calendar.component(.weekday, from: date)
        guard let targetWeekday = Weekday(calendarWeekday: weekdayComponent) else {
            return []
        }
        
        let allTrackers = fetchTrackers()
        var categories: [String: [Tracker]] = [:]
        
        for tracker in allTrackers {
            
            if tracker.schedule.contains(targetWeekday) {
                let categoryTitle = trackerCategoryStore.categoryTitle(for: tracker) ?? "Без категории"
                
                if categories[categoryTitle] == nil {
                    categories[categoryTitle] = []
                }
                categories[categoryTitle]?.append(tracker)
            }
        }
        
        let result = categories.map { TrackerCategory(title: $0.key, trackers: $0.value) }
            .sorted { $0.title < $1.title }
        
        return result
    }
    
    func deleteTracker(_ tracker: Tracker) throws {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        let results = try context.fetch(fetchRequest)
        if let trackerToDelete = results.first {
            context.delete(trackerToDelete)
            DataBaseStore.shared.saveContext()
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateTrackers()
    }
}
