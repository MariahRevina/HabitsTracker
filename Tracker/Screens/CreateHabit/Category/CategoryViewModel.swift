import Foundation

final class CategoryViewModel {
    
    // MARK: - Binding Closures
    var onCategoriesUpdate: (() -> Void)?
    var onCategorySelected: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onShowEditDialog: ((String) -> Void)?
    var onShowDeleteConfirmation: ((String) -> Void)?
    
    // MARK: - Properties
    private let trackerCategoryStore: TrackerCategoryStore
    private(set) var categories: [TrackerCategory] = [] {
        didSet {
            onCategoriesUpdate?()
        }
    }
    
    var selectedCategory: String?
    
    // MARK: - Initialization
    init(trackerCategoryStore: TrackerCategoryStore, selectedCategory: String? = nil) {
        self.trackerCategoryStore = trackerCategoryStore
        self.selectedCategory = selectedCategory
    }
    
    // MARK: - Public Methods
    func loadCategories() {
        do {
            categories = try trackerCategoryStore.fetchAllCategoriesWithTrackers()
        } catch {
            onError?("Не удалось загрузить категории")
        }
    }
    
    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        let category = categories[index]
        selectedCategory = category.title
        onCategorySelected?(category.title)
    }
    
    func createCategory(with title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError?(CategoryError.emptyTitle.errorDescription ?? "Название не может быть пустым")
            return
        }
        
        do {
            try trackerCategoryStore.createCategory(with: title)
            loadCategories()
        } catch let error as CategoryError {
            onError?(error.errorDescription ?? "Неизвестная ошибка")
        } catch {
            onError?("Не удалось создать категорию")
        }
    }
    
    func updateCategory(oldTitle: String, newTitle: String) {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError?(CategoryError.emptyTitle.errorDescription ?? "Название не может быть пустым")
            return
        }
        
        do {
            try trackerCategoryStore.updateCategory(oldTitle: oldTitle, newTitle: newTitle)
            
            // Обновляем выбранную категорию если она была изменена
            if selectedCategory == oldTitle {
                selectedCategory = newTitle
            }
            
            loadCategories()
        } catch let error as CategoryError {
            onError?(error.errorDescription ?? "Неизвестная ошибка")
        } catch {
            onError?("Не удалось обновить категорию")
        }
    }
    
    func deleteCategory(with title: String) {
        do {
            try trackerCategoryStore.deleteCategory(with: title)
            
            // Сбрасываем выбранную категорию если она была удалена
            if selectedCategory == title {
                selectedCategory = nil
            }
            
            loadCategories()
        } catch {
            onError?("Не удалось удалить категорию")
        }
    }
    
    func handleLongPress(on categoryTitle: String) {
        onShowEditDialog?(categoryTitle)
    }
    
    func requestDeleteConfirmation(for categoryTitle: String) {
        onShowDeleteConfirmation?(categoryTitle)
    }
    
    // MARK: - Data Preparation for TableView
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    func categoryTitle(at index: Int) -> String? {
        guard index < categories.count else { return nil }
        return categories[index].title
    }
    
    func isCategorySelected(at index: Int) -> Bool {
        guard index < categories.count else { return false }
        return categories[index].title == selectedCategory
    }
    
    func hasCategories() -> Bool {
        return !categories.isEmpty
    }
}
