import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private lazy var trackersLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .black
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
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        searchBar.layer.cornerRadius = 8
        searchBar.clipsToBounds = true
        searchBar.delegate = self
        
        let searchTextField = searchBar.searchTextField
        searchTextField.backgroundColor = UIColor(red: 0.46, green: 0.46, blue: 0.50, alpha: 0.12)
        
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
        imageView.image = UIImage(named: "star")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
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
    
    // MARK: - Properties
    
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: Set<TrackerRecord> = []
    private let calendar = Calendar.current
    var currentDate: Date {
        return datePicker.date
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        createMockData()
        reloadData()
        updatePlaceholderVisibility()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(trackersLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(placeholderStack)
        
        setupConstraints()
    }
    
    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(named: "plus"),
            style: .plain,
            target: self,
            action: #selector(addTrackerTapped)
        )
        addButton.tintColor = .black
        addButton.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = datePickerItem
        
        navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets.zero
        navigationItem.leftBarButtonItem?.setBackgroundVerticalPositionAdjustment(0, for: .default)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            trackersLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            trackersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: trackersLabel.bottomAnchor, constant: 7),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func addTrackerTapped() {
        let createHabitVC = CreateHabitScreen()
            createHabitVC.delegate = self
            present(createHabitVC, animated: true)
    }
    
    private func datePickerValueChanged() {
        reloadData()
        updateCompleteButtonsState()
    }
    
    private func reloadData() {
        let selectedDate = datePicker.date
        let filterWeekday = calendar.component(.weekday, from: selectedDate)
        
        print("🔍 Фильтрация по дню недели: \(filterWeekday)")
           print("📊 Всего категорий: \(categories.count)")
        
        visibleCategories = categories.map { category in
            let filteredTrackers = category.trackers.filter { tracker in
                tracker.shedule.contains { weekday in
                    weekday.numberValue == filterWeekday
                }
                        }
            print("📁 Категория '\(category.title)': \(category.trackers.count) трекеров -> \(filteredTrackers.count) после фильтрации")
                    return TrackerCategory(title: category.title, trackers: filteredTrackers)
                }.filter { !$0.trackers.isEmpty }
                
                print("👀 Видимых категорий: \(visibleCategories.count)")
        collectionView.reloadData()
            updatePlaceholderVisibility()
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
        placeholderStack.isHidden = hasVisibleTrackers
        collectionView.isHidden = !hasVisibleTrackers
    }
    
    private func isTrackerCompletedToday(_ trackerId: UUID) -> Bool {
        let selectedDate = datePicker.date
        return completedTrackers.contains(TrackerRecord(trackerId: trackerId, date: selectedDate))
    }
    
    private func completeTracker(_ trackerId: UUID) {
        let selectedDate = datePicker.date
        let today = Date()
        
        guard selectedDate <= today else { return }
        
        let record = TrackerRecord(trackerId: trackerId, date: selectedDate)
        completedTrackers.insert(record)
        updateCompleteButtonsState()
    }
    
    private func uncompleteTracker(_ trackerId: UUID) {
        let selectedDate = datePicker.date
        completedTrackers.remove(TrackerRecord(trackerId: trackerId, date: selectedDate))
        updateCompleteButtonsState()
    }
    
    // MARK: - Mock Data
    
    private func createMockData() {
        let mockTrackers = [
            Tracker(
                id: UUID(),
                name: "Yoga time",
                color: .systemGreen,
                shedule: [.monday],
                emoji: "🤸‍♂️"
            ),
            Tracker(
                id: UUID(),
                name: "Замечать приятное вокруг",
                color: .systemOrange,
                shedule: [.monday],
                emoji: "🤗"
            ),
            Tracker(
                id: UUID(),
                name: "Заниматься ios-программированием",
                color: .systemBlue,
                shedule: [.monday, .tuesday, .thursday, .friday],
                emoji: "😫"
            ),
            Tracker(
                id: UUID(),
                name: "Чтение книг с ребёнком",
                color: .systemPurple,
                shedule: [.monday],
                emoji: "❤️"
            )
        ]
        
        categories = [
            TrackerCategory(title: "Физическое Развитие", trackers: [mockTrackers[0]]),
            TrackerCategory(title: "Умственное Развитие", trackers: [mockTrackers[2]]),
            TrackerCategory(title: "Ментальное здоровье", trackers: [mockTrackers[1]]),
            TrackerCategory(title: "Родительство", trackers: [mockTrackers[3]])
        ]
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCell", for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        let isCompletedToday = isTrackerCompletedToday(tracker.id)
        
        cell.configure(
            with: tracker,
            completedDays: completedDays,
            isCompletedToday: isCompletedToday
        )
        
        cell.onCompleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            if isCompletedToday {
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
}

// MARK: - UISearchBarDelegate
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Реализация поиска будет добавлена позже
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        var newCategories = categories
        if let index = newCategories.firstIndex(where: { $0.title == categoryTitle }) {
            var updatedTrackers = newCategories[index].trackers
            updatedTrackers.append(tracker)
            newCategories[index] = TrackerCategory(title: categoryTitle, trackers: updatedTrackers)
        } else {
            
            let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
            newCategories.append(newCategory)
        }
        categories = newCategories
        reloadData()
        
        dismiss(animated: true)
    }
}
