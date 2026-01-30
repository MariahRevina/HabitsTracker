import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Properties
    var trackerStore: TrackerStore?
    var trackerRecordStore: TrackerRecordStore?
    
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    private let calendar = Calendar.current
    var currentDate: Date {
        return datePicker.date
    }
    
    private var currentFilter: FilterType = .allTrackers
    private var isFilterApplied: Bool = false
    private var searchText: String = ""
    
    // MARK: - UI Elements
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("filters_button", comment: "Filters button title"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .yBlue
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .plus), for: .normal)
        button.tintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : UIColor( resource: .yBlackDay)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addTrackerTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var trackersLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("trackers_title", comment: "Main screen title")
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : UIColor( resource: .yBlackDay)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "ru_RU")
        picker.preferredDatePickerStyle = .compact
        picker.backgroundColor = .clear
        picker.translatesAutoresizingMaskIntoConstraints = false
        
        picker.addAction(UIAction { [weak self] _ in
            self?.datePickerValueChanged()
        }, for: .valueChanged)
        
        return picker
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("search_placeholder", comment: "Search placeholder")
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        searchBar.layer.cornerRadius = 8
        searchBar.clipsToBounds = true
        searchBar.delegate = self
        searchBar.searchTextField.textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : UIColor(resource: .yBlackDay)
        }
        searchBar.searchTextField.backgroundColor = .search
        
        return searchBar
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .star)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : UIColor(resource: .yBlackDay)}
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var placeholderStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [placeholderImageView, placeholderLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        
        trackerStore?.delegate = self
        
        loadData()
        reloadData()
        updatePlaceholderVisibility()
        updateFilterButtonVisibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentFilter == .todayTrackers {
            let calendar = Calendar.current
            let selectedDate = calendar.startOfDay(for: datePicker.date)
            let today = calendar.startOfDay(for: Date())
            
            if selectedDate != today {
                datePicker.date = Date()
                searchText = ""
                searchBar.text = ""
                reloadData()
            }
        }
    }
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(resource: .yBlackDay) : .white
        }
        
        view.addSubview(addButton)
        view.addSubview(trackersLabel)
        view.addSubview(datePicker)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(placeholderStack)
        view.addSubview(filterButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Кнопка "+"
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            addButton.widthAnchor.constraint(equalToConstant: 42),
            addButton.heightAnchor.constraint(equalToConstant: 42),
            
            // Заголовок "Трекеры"
            trackersLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 1),
            trackersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trackersLabel.trailingAnchor.constraint(lessThanOrEqualTo: datePicker.leadingAnchor, constant: -8),
            
            // DatePicker
            datePicker.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            datePicker.widthAnchor.constraint(equalToConstant: 120),
            
            // SearchBar
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: trackersLabel.bottomAnchor, constant: 7),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            // CollectionView
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Placeholder
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Кнопка фильтров
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func addTrackerTapped() {
        let createHabitVC = CreateHabitScreen(mode: .create)
        createHabitVC.delegate = self
        let navController = UINavigationController(rootViewController: createHabitVC)
        present(navController, animated: true)
    }
    
    @objc private func filterButtonTapped() {
        LoggerService.shared.trace("Filter button tapped")
        
        let filterVC = FilterViewController(currentFilter: currentFilter, isFilterApplied: isFilterApplied)
        filterVC.delegate = self
        filterVC.modalPresentationStyle = .pageSheet
        
        if let sheet = filterVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(filterVC, animated: true)
    }
    
    private func datePickerValueChanged() {
        searchText = ""
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        reloadData()
        updateCompleteButtonsState()
        updateFilterButtonVisibility()
    }
    
    private func loadData() {
        guard let trackerRecordStore = trackerRecordStore else {return}
        completedTrackers = trackerRecordStore.fetchCompletedTrackers()
    }
    
    private func reloadData() {
        guard let trackerStore = trackerStore else { return }
        let selectedDate = datePicker.date
        
        let calendar = Calendar.current
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        let normalizedToday = calendar.startOfDay(for: Date())
        
        if currentFilter == .todayTrackers && normalizedSelectedDate != normalizedToday {
            
            currentFilter = .allTrackers
            isFilterApplied = false
            LoggerService.shared.trace("Date changed manually, resetting filter to .allTrackers")
        }
        
        var allTrackers = trackerStore.fetchTrackers(for: selectedDate)
        
        if !searchText.isEmpty {
            allTrackers = filterTrackersBySearch(allTrackers, searchText: searchText)
        }
        
        switch currentFilter {
        case .allTrackers:
            visibleCategories = allTrackers
            
        case .todayTrackers:
            
            if normalizedSelectedDate != normalizedToday {
                datePicker.date = Date()
            }
            let today = Date()
            var todayTrackers = trackerStore.fetchTrackers(for: today)
            if !searchText.isEmpty {
                todayTrackers = filterTrackersBySearch(todayTrackers, searchText: searchText)
            }
            visibleCategories = todayTrackers
            
        case .completed:
            
            filterCompletedTrackers(from: &allTrackers)
            visibleCategories = allTrackers.filter { !$0.trackers.isEmpty }
            
        case .notCompleted:
            filterNotCompletedTrackers(from: &allTrackers)
            visibleCategories = allTrackers.filter { !$0.trackers.isEmpty }
        }
        
        updateFilterButtonVisibility()
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
    
    private func filterTrackersBySearch(_ categories: [TrackerCategory], searchText: String) -> [TrackerCategory] {
        let searchTextLowercased = searchText.lowercased()
        
        var filteredCategories: [TrackerCategory] = []
        
        for category in categories {
            let filteredTrackers = category.trackers.filter { tracker in
                tracker.name.lowercased().contains(searchTextLowercased)
            }
            
            if !filteredTrackers.isEmpty {
                let filteredCategory = TrackerCategory(
                    title: category.title,
                    trackers: filteredTrackers
                )
                filteredCategories.append(filteredCategory)
            }
        }
        
        return filteredCategories
    }
    
    private func filterCompletedTrackers(from categories: inout [TrackerCategory]) {
        for i in 0..<categories.count {
            categories[i].trackers = categories[i].trackers.filter { tracker in
                isTrackerCompletedToday(tracker.id)
            }
        }
        visibleCategories = categories.filter { !$0.trackers.isEmpty }
    }
    
    private func filterNotCompletedTrackers(from categories: inout [TrackerCategory]) {
        for i in 0..<categories.count {
            categories[i].trackers = categories[i].trackers.filter { tracker in
                !isTrackerCompletedToday(tracker.id)
            }
        }
        visibleCategories = categories.filter { !$0.trackers.isEmpty }
    }
    
    private func updateFilterButtonVisibility() {
        let hasTrackersForSelectedDate = !visibleCategories.isEmpty
        filterButton.isHidden = !hasTrackersForSelectedDate
    }
    
    private func updateCompleteButtonsState() {
        for case let cell as TrackerCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
            let isCompletedToday = isTrackerCompletedToday(tracker.id)
            
            cell.updateCompleteButton(isCompletedToday: isCompletedToday, color: tracker.color)
        }
    }
    
    private func updatePlaceholderVisibility() {
        let hasVisibleTrackers = visibleCategories.contains { !$0.trackers.isEmpty }
        
        if hasVisibleTrackers {
            placeholderStack.isHidden = true
            collectionView.isHidden = false
        } else {
            if !searchText.isEmpty {
                placeholderImageView.image = UIImage(resource: .notFound)
                placeholderLabel.text = "Ничего не найдено"
            } else if currentFilter != .allTrackers && currentFilter != .todayTrackers {
                placeholderImageView.image = UIImage(resource: .notFound)
                placeholderLabel.text = "Ничего не найдено"
            } else {
                placeholderImageView.image = UIImage(resource: .star)
                placeholderLabel.text = "Что будем отслеживать?"
            }
            placeholderStack.isHidden = false
            collectionView.isHidden = true
        }
    }
    
    private func isTrackerCompletedToday(_ trackerId: UUID) -> Bool {
        guard let trackerRecordStore = trackerRecordStore else { return false }
        return trackerRecordStore.isTrackerCompleted(trackerId, on: datePicker.date)
    }
    
    private func completeTracker(_ trackerId: UUID) {
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let today = Date()
        
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        let normalizedToday = calendar.startOfDay(for: today)
        
        guard normalizedSelectedDate <= normalizedToday,
              let trackerRecordStore = trackerRecordStore else { return }
        
        do {
            try trackerRecordStore.addRecord(for: trackerId, date: normalizedSelectedDate)
            completedTrackers = trackerRecordStore.fetchCompletedTrackers()
            
            if currentFilter == .completed || currentFilter == .notCompleted {
                reloadData()
            } else {
                if let indexPath = findIndexPathForTracker(with: trackerId) {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        } catch {
            LoggerService.shared.error("Failed to complete tracker: \(error)")
        }
    }
    
    private func uncompleteTracker(_ trackerId: UUID) {
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        
        guard let trackerRecordStore = trackerRecordStore else { return }
        
        do {
            try trackerRecordStore.removeRecord(for: trackerId, date: normalizedSelectedDate)
            completedTrackers = trackerRecordStore.fetchCompletedTrackers()
            
            if currentFilter == .completed || currentFilter == .notCompleted {
                reloadData()
            } else {
                if let indexPath = findIndexPathForTracker(with: trackerId) {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        } catch {
            LoggerService.shared.error("Failed to uncomplete tracker: \(error)")
        }
    }
    
    private func findIndexPathForTracker(with id: UUID) -> IndexPath? {
        for (sectionIndex, category) in visibleCategories.enumerated() {
            for (itemIndex, tracker) in category.trackers.enumerated() {
                if tracker.id == id {
                    return IndexPath(item: itemIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
}

// MARK: - UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCell", for: indexPath) as? TrackerCell,
              let trackerRecordStore = trackerRecordStore else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let completedDays = trackerRecordStore.completedDaysCount(for: tracker.id)
        
        let isCompletedToday = isTrackerCompletedToday(tracker.id)
        
        cell.configure(
            with: tracker,
            completedDays: completedDays,
            isCompletedToday: isCompletedToday
        )
        
        cell.onCompleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            let isCurrentlyCompleted = self.isTrackerCompletedToday(tracker.id)
            if isCurrentlyCompleted {
                self.uncompleteTracker(tracker.id)
            } else {
                self.completeTracker(tracker.id)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as? HeaderView else {
            return UICollectionReusableView()
        }
        
        header.configure(with: visibleCategories[indexPath.section].title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.frame.width - 9
        let cellWidth = availableWidth / 2
        return CGSize(width: cellWidth, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 46)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        return UIContextMenuConfiguration(
            identifier: tracker.id as NSCopying,
            previewProvider: nil
        ) { [weak self] _ in
            return self?.createContextMenu(for: tracker, at: indexPath)
        }
    }
    
    private func createContextMenu(for tracker: Tracker, at indexPath: IndexPath) -> UIMenu {
        
        let editAction = UIAction(title: NSLocalizedString("edit_action", comment: "Редактировать")) { [weak self] _ in
            self?.editTracker(tracker, at: indexPath)
        }
        let deleteAction = UIAction(title: NSLocalizedString("delete_action", comment: "Удалить"),
                                    attributes: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: tracker, at: indexPath)
        }
        
        return UIMenu (children: [editAction, deleteAction])
    }
    
    private func showDeleteConfirmation(for tracker: Tracker, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: NSLocalizedString("delete_confirmation_title", comment: "Удалить трекер?"),
            message: "",
            preferredStyle: .actionSheet
        )
        let deleteAction = UIAlertAction(title: NSLocalizedString("delete_action", comment: "Удалить"), style: .destructive) { [weak self] _ in
            
            guard let self = self,
                  let currentIndexPath = self.findIndexPathForTracker(with: tracker.id) else {
                LoggerService.shared.error("Tracker not found for deletion")
                return
            }
            
            self.deleteTracker(tracker, at: currentIndexPath)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel_button", comment: "Отменить"), style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func deleteTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        guard let trackerStore = trackerStore else {
            LoggerService.shared.error("TrackerStore is nil")
            return
        }
        do {
            try trackerStore.deleteTracker(tracker)
            
            guard indexPath.section < visibleCategories.count,
                  indexPath.item < visibleCategories[indexPath.section].trackers.count,
                  visibleCategories[indexPath.section].trackers[indexPath.item].id == tracker.id else {
                
                LoggerService.shared.warning("IndexPath outdated, reloading data")
                reloadData()
                return
            }
            
            // Удаляем из локальных данных
            visibleCategories[indexPath.section].trackers.remove(at: indexPath.item)
            
            // Логируем для отладки
            LoggerService.shared.trace("""
            Deleting tracker:
            - Section: \(indexPath.section)
            - Item: \(indexPath.item)
            - Category count: \(visibleCategories.count)
            - Trackers in section: \(visibleCategories[indexPath.section].trackers.count)
            """)
            
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: [indexPath])
            }, completion: { _ in
                self.updatePlaceholderVisibility()
            })
        } catch {
            LoggerService.shared.error("Unsuccessful tracker deletion: \(error)")
        }
    }
    
    private func editTracker(_ tracker: Tracker, at indexPath: IndexPath) {
        let categoryTitle = visibleCategories[indexPath.section].title
        let editVC = CreateHabitScreen(mode: .edit(tracker: tracker, categoryTitle: categoryTitle))
        editVC.delegate = self
        let navController = UINavigationController(rootViewController: editVC)
        present(navController, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TrackersViewController: TrackerStoreDelegate {
    func didUpdateTrackers() {
        searchText = ""
        searchBar.text = ""
        searchBar.resignFirstResponder()
        reloadData()
    }
}

extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        guard let trackerStore = trackerStore else {return}
        
        do {
            try trackerStore.createTracker(tracker, categoryTitle: categoryTitle)
            searchText = ""
            searchBar.text = ""
            dismiss(animated: true)
        } catch {
            let alert = UIAlertController(
                title: "Ошибка",
                message: "Не удалось создать трекер",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    func didUpdateTracker(_ tracker: Tracker, categoryTitle: String) {
        guard let trackerStore = trackerStore else { return }
        
        do {
            try trackerStore.updateTracker(tracker, categoryTitle: categoryTitle)
            searchText = ""
            searchBar.text = ""
            dismiss(animated: true)
        } catch {
            LoggerService.shared.error("Failed to update tracker: \(error)")
            
            let alert = UIAlertController(
                title: "Ошибка",
                message: "Не удалось обновить привычку",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
extension TrackersViewController: FilterViewControllerDelegate {
    func didSelectFilter(_ filter: FilterType) {
        currentFilter = filter
        
        switch filter {
        case .allTrackers, .todayTrackers:
            isFilterApplied = true
        case .completed, .notCompleted:
            isFilterApplied = true
        }
        searchText = ""
        searchBar.text = ""
        searchBar.resignFirstResponder()
        reloadData()
    }
    
    private func updatePlaceholderForFilter() {
        if visibleCategories.isEmpty {
            placeholderImageView.image = UIImage(resource: .notFound)
            placeholderLabel.text = "Ничего не найдено"
            placeholderStack.isHidden = false
            collectionView.isHidden = true
        }
    }
}
