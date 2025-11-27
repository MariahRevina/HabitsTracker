import CoreData

final class TrackerCategoryStore {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Методы для TrackerStore (существующие)
    func fetchOrCreateCategory(with title: String) throws -> TrackerCategoryCoreData {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        let results = try context.fetch(fetchRequest)
        
        if let existingCategory = results.first {
            return existingCategory
        } else {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.title = title
            return newCategory
        }
    }
    
    func categoryTitle(for tracker: Tracker) -> String? {
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.category?.title
        } catch {
            LoggerService.shared.error("Failed to fetch category title: \(error)")
            return nil
        }
    }
    
    func fetchAllCategories() throws -> [String] {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let results = try context.fetch(fetchRequest)
        return results.compactMap { $0.title }
    }
    
    // MARK: - Новые методы для MVVM
    func fetchAllCategoriesWithTrackers() throws -> [TrackerCategory] {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let results = try context.fetch(fetchRequest)
        return results.compactMap { coreDataCategory in
            guard let title = coreDataCategory.title,
                  let trackersSet = coreDataCategory.trackers as? Set<TrackerCoreData> else {
                return nil
            }
            
            let trackers = trackersSet.compactMap { coreDataTracker -> Tracker? in
                guard let id = coreDataTracker.id,
                      let name = coreDataTracker.name,
                      let colorHex = coreDataTracker.color,
                      let emoji = coreDataTracker.emoji else {
                    return nil
                }
                
                let colorMarshalling = UIColorMarshalling()
                let color = colorMarshalling.color(from: colorHex)
                
                var schedule: [Weekday] = []
                if let scheduleData = coreDataTracker.schedule,
                   let scheduleArray = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: scheduleData) as? [String] {
                    schedule = scheduleArray.compactMap { Weekday(rawValue: $0) }
                }
                
                return Tracker(
                    id: id,
                    name: name,
                    color: color,
                    schedule: schedule,
                    emoji: emoji
                )
            }
            
            return TrackerCategory(title: title, trackers: trackers)
        }
    }
    
    // MARK: - Создание категории
    func createCategory(with title: String) throws {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        let existingCategories = try context.fetch(fetchRequest)
        guard existingCategories.isEmpty else {
            throw CategoryError.categoryAlreadyExists
        }
        
        let newCategory = TrackerCategoryCoreData(context: context)
        newCategory.title = title
        
        try context.save()
    }
    
    // MARK: - Обновление категории
    func updateCategory(oldTitle: String, newTitle: String) throws {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", oldTitle)
        
        let results = try context.fetch(fetchRequest)
        guard let categoryToUpdate = results.first else {
            throw CategoryError.categoryNotFound
        }
        
        // Проверяем, что новое название не совпадает с существующим
        let checkRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        checkRequest.predicate = NSPredicate(format: "title == %@", newTitle)
        let existingWithNewTitle = try context.fetch(checkRequest)
        
        if !existingWithNewTitle.isEmpty && newTitle != oldTitle {
            throw CategoryError.categoryAlreadyExists
        }
        
        categoryToUpdate.title = newTitle
        try context.save()
    }
    
    // MARK: - Удаление категории
    func deleteCategory(with title: String) throws {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        let results = try context.fetch(fetchRequest)
        guard let categoryToDelete = results.first else {
            throw CategoryError.categoryNotFound
        }
        
        context.delete(categoryToDelete)
        try context.save()
    }
    
    // MARK: - Получение категории по названию
    func fetchCategory(with title: String) throws -> TrackerCategoryCoreData? {
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        let results = try context.fetch(fetchRequest)
        return results.first
    }
}

// MARK: - Ошибки категорий
enum CategoryError: Error, LocalizedError {
    case categoryAlreadyExists
    case categoryNotFound
    case emptyTitle
    
    var errorDescription: String? {
        switch self {
        case .categoryAlreadyExists:
            return "Категория с таким названием уже существует"
        case .categoryNotFound:
            return "Категория не найдена"
        case .emptyTitle:
            return "Название категории не может быть пустым"
        }
    }
}
