import CoreData

final class TrackerRecordStore {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func addRecord(for trackerId: UUID, date: Date) throws {
        let record = TrackerRecordCoreData(context: context)
        record.trackerId = trackerId
        let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: date)
            record.date = normalizedDate
        
            DataBaseStore.shared.saveContext()
    }
    
    func removeRecord(for trackerId: UUID, date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "trackerId == %@ AND date >= %@ AND date < %@",
            trackerId as CVarArg,
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        
        let results = try context.fetch(fetchRequest)
        if let recordToDelete = results.first {
            context.delete(recordToDelete)
            DataBaseStore.shared.saveContext()
        }
    }
    
    func fetchCompletedTrackers() -> Set<TrackerRecord> {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            var records = Set<TrackerRecord>()
            
            for recordCoreData in results {
                guard let trackerId = recordCoreData.trackerId,
                      let date = recordCoreData.date else {
                    continue
                }
                records.insert(TrackerRecord(trackerId: trackerId, date: date))
            }
            
            return records
        } catch {
            print("Failed to fetch completed trackers: \(error)")
            return []
        }
    }
    
    func completedDaysCount(for trackerId: UUID) -> Int {
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "trackerId == %@", trackerId as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.count
        } catch {
            print("Failed to fetch completed days count: \(error)")
            return 0
        }
    }
    
    func isTrackerCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "trackerId == %@ AND date >= %@ AND date < %@",
            trackerId as CVarArg,
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Failed to check if tracker is completed: \(error)")
            return false
        }
    }
}
