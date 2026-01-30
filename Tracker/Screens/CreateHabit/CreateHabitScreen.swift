import UIKit

enum TrackerFormMode {
    case create
    case edit(tracker: Tracker, categoryTitle: String)
}

final class CreateHabitScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CreateTrackerViewControllerDelegate?
    private var mode: TrackerFormMode = .create
    private var selectedCategory: String?
    private var selectedSchedule: [Weekday] = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private var completedDays: Int = 0
    private var scrollViewTopConstraint: NSLayoutConstraint?
    private let options = ["Категория", "Расписание"]
    private enum Constants {
        static let emojiCellIdentifier = "emojiCell"
        static let colorCellIdentifier = "colorCell"
        static let headerIdentifier = "header"
    }
    
    // MARK: - UI Elements
    
    private lazy var nameScreen: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .yBlackDay
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var daysCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 дней"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .yBlackDay
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.layer.cornerRadius = 16
        textField.backgroundColor = UIColor {traits in
            traits.userInterfaceStyle == .dark ? UIColor(resource: .textfieldBackground) : .yLightGray}
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private lazy var clearTextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .yGray
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    } ()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .yRed
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    } ()
    
    private lazy var optionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(resource: .textfieldBackground) : .yLightGray
        }
        tableView.separatorColor = .yGray
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: Constants.emojiCellIdentifier)
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: Constants.colorCellIdentifier)
        collectionView.register(EmojiAndColorsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: Constants.headerIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.yRed, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.yRed.cgColor
        button.backgroundColor  = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(resource: .yBlackDay) : .white
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated:true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.backgroundColor = .yGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.performAction()
        }, for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - Initializers
    
    convenience init(mode: TrackerFormMode) {
        self.init()
        self.mode = mode
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureForMode()
        updateActionButtonState()
        collectionView.allowsMultipleSelection = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if case .edit = mode {
            selectCurrentEmojiAndColor()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        view.backgroundColor = UIColor {traits in
            traits.userInterfaceStyle == .dark ? UIColor(resource: .yBlackDay) : .white}
        
        textField.delegate = self
        
        view.addSubview(nameScreen)
        view.addSubview(scrollView)
        view.addSubview(actionButton)
        view.addSubview(cancelButton)
        
        view.addSubview(daysCountLabel)
        
        scrollView.addSubview(textField)
        scrollView.addSubview(optionsTableView)
        scrollView.addSubview(collectionView)
        scrollView.addSubview(clearTextButton)
        scrollView.addSubview(errorLabel)
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        textField.addAction(UIAction { [weak self] _ in
            self?.textFieldChanged()
        }, for: .editingChanged)
        
        clearTextButton.addAction(UIAction { [weak self] _ in
            self?.clearTextField()
        }, for: .touchUpInside)
        
        setupConstraints()
        
    }
    
    private func setupConstraints() {
        scrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: daysCountLabel.bottomAnchor, constant: 40)
        
        NSLayoutConstraint.activate([
            
            nameScreen.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            nameScreen.heightAnchor.constraint(equalToConstant: 22),
            
            daysCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            daysCountLabel.topAnchor.constraint(equalTo: nameScreen.bottomAnchor, constant: 38),
            daysCountLabel.heightAnchor.constraint(equalToConstant: 38),
            
            scrollViewTopConstraint!,
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            
            textField.topAnchor.constraint(equalTo: scrollView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            
            clearTextButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            clearTextButton.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -16),
            clearTextButton.widthAnchor.constraint(equalToConstant: 17),
            clearTextButton.heightAnchor.constraint(equalToConstant: 17),
            
            errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            optionsTableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24),
            optionsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            optionsTableView.heightAnchor.constraint(equalToConstant: 150),
            
            collectionView.topAnchor.constraint(equalTo: optionsTableView.bottomAnchor, constant: 32),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 460),
            
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -4),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            actionButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 4),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 60),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Private Methods
    
    private func configureForMode() {
        switch mode {
        case .create:
            nameScreen.text = "Новая привычка"
            actionButton.setTitle("Создать", for: .normal)
            clearTextButton.alpha = 0
            
            daysCountLabel.isHidden = true
            scrollViewTopConstraint?.isActive = false
            
            let createConstraint = scrollView.topAnchor.constraint(equalTo: nameScreen.bottomAnchor, constant: 24)
            createConstraint.isActive = true
            scrollViewTopConstraint = createConstraint
            
        case .edit(let tracker, let categoryTitle):
            nameScreen.text = "Редактирование привычки"
            actionButton.setTitle("Сохранить", for: .normal)
            
            textField.text = tracker.name
            selectedCategory = categoryTitle
            selectedSchedule = tracker.schedule
            selectedEmoji = tracker.emoji
            selectedColor = tracker.color
            daysCountLabel.isHidden = false
            scrollViewTopConstraint?.isActive = false
            let editConstraint = scrollView.topAnchor.constraint(equalTo: daysCountLabel.bottomAnchor, constant: 40)
            editConstraint.isActive = true
            scrollViewTopConstraint = editConstraint
            updateCompletedDaysCount(for: tracker.id)
            
            updateClearButtonVisibility()
            updateActionButtonState()
            
            optionsTableView.reloadData()
        }
    }
    
    private func updateCompletedDaysCount(for trackerId: UUID) {
        let trackerRecordStore = TrackerRecordStore(context: DataBaseStore.shared.viewContext)
        let count = trackerRecordStore.completedDaysCount(for: trackerId)
        completedDays = count
        updateDaysCountLabel()
    }
    
    private func updateDaysCountLabel() {
        let daysString = formatDaysString(completedDays)
        daysCountLabel.text = daysString
        daysCountLabel.isHidden = false
    }
    
    private func formatDaysString(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "\(count) дней"
        }
        
        switch lastDigit {
        case 1:
            return "\(count) день"
        case 2, 3, 4:
            return "\(count) дня"
        default:
            return "\(count) дней"
        }
    }
    
    private func selectCurrentEmojiAndColor() {
        guard let selectedEmoji = selectedEmoji,
              let selectedColor = selectedColor else { return }
        
        if let emojiIndex = AppData.emojis.firstIndex(of: selectedEmoji) {
            let indexPath = IndexPath(item: emojiIndex, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            if let cell = collectionView.cellForItem(at: indexPath) as? EmojiCell {
                cell.isSelected = true
            }
        }
        
        if let colorIndex = AppData.colors.firstIndex(where: {
            UIColorMarshalling.hexString(from: $0) == UIColorMarshalling.hexString(from: selectedColor)
        }) {
            let indexPath = IndexPath(item: colorIndex, section: 1)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            if let cell = collectionView.cellForItem(at: indexPath) as? ColorCell {
                cell.isSelected = true
            }
        }
    }
    private func performAction() {
        switch mode {
        case .create:
            createTracker()
        case .edit(let tracker, _):
            updateTracker(tracker)
        }
    }
    
    private func createTracker() {
        guard let name = textField.text, !name.isEmpty,
              let category = selectedCategory,
              !selectedSchedule.isEmpty,
              let emoji = selectedEmoji,
              let color = selectedColor
        else {
            LoggerService.shared.error(
                """
                Попытка создания трекера с незаполненными полями:
                - имя: \(textField.text ?? "nil")
                - категория: \(selectedCategory ?? "nil") 
                - расписание: \(selectedSchedule.count) дней
                - эмодзи: \(selectedEmoji ?? "nil")
                - цвет: \(selectedColor != nil ? "выбран" : "не выбран")
                """
            )
            return
        }
        
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: color,
            schedule: selectedSchedule,
            emoji: emoji
        )
        delegate?.didCreateTracker(newTracker, categoryTitle: category)
        presentingViewController?.dismiss(animated: true)
    }
    
    private func updateTracker(_ originalTracker: Tracker) {
        guard let name = textField.text, !name.isEmpty,
              let category = selectedCategory,
              !selectedSchedule.isEmpty,
              let emoji = selectedEmoji,
              let color = selectedColor
        else {
            LoggerService.shared.error(
                    """
                    Попытка обновления трекера с незаполненными полями:
                    - имя: \(textField.text ?? "nil")
                    - категория: \(selectedCategory ?? "nil") 
                    - расписание: \(selectedSchedule.count) дней
                    - эмодзи: \(selectedEmoji ?? "nil")
                    - цвет: \(selectedColor != nil ? "выбран" : "не выбран")
                    """
            )
            return
        }
        
        let updatedTracker = Tracker(
            id: originalTracker.id,
            name: name,
            color: color,
            schedule: selectedSchedule,
            emoji: emoji
        )
        delegate?.didUpdateTracker(updatedTracker, categoryTitle: category)
        presentingViewController?.dismiss(animated: true)
    }
    
    private func textFieldChanged() {
        updateActionButtonState()
        updateClearButtonVisibility()
        validateTextLength()
    }
    
    private func clearTextField() {
        textField.text = ""
        textFieldChanged()
        textField.becomeFirstResponder()
    }
    
    private func updateClearButtonVisibility() {
        let hasText = !(textField.text?.isEmpty ?? true)
        UIView.animate(withDuration: 0.2) {
            self.clearTextButton.alpha = hasText ? 1 : 0
        }
    }
    
    private func validateTextLength() {
        guard let text = textField.text else { return }
        if text.count >= 38 {
            let index = text.index(text.startIndex, offsetBy: 38)
            textField.text = String(text[..<index])
            
            UIView.animate(withDuration: 0.2) {
                self.errorLabel.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.errorLabel.alpha = 0
            }
        }
    }
    
    private func updateActionButtonState() {
        let isNameEmpty = textField.text?.isEmpty ?? true
        let isCategorySelected = selectedCategory != nil
        let isScheduleSelected = !selectedSchedule.isEmpty
        let isEmojiSelected = selectedEmoji != nil
        let isColorSelected = selectedColor != nil
        let isReady = !isNameEmpty && isCategorySelected && isScheduleSelected && isEmojiSelected && isColorSelected
        
        actionButton.isEnabled = isReady
        updateActionButtonAppearance()
    }
    
    private func updateActionButtonAppearance() {
        let isReady = actionButton.isEnabled
        actionButton.backgroundColor = isReady ? .black : .yGray
        actionButton.setTitleColor(.white, for: .normal)
    }
    
    private func formatScheduleText(_ schedule: [Weekday]) -> String {
        if schedule.count == Weekday.allCases.count {
            return "Каждый день"
        } else {
            let sortedSchedule = schedule.sorted {
                $0.bitValue < $1.bitValue
            }
            return sortedSchedule.map { $0.shortName }.joined(separator: ", ")
        }
    }
}

// MARK: - UITableViewDelegate

extension CreateHabitScreen: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            let categoryStore = TrackerCategoryStore(context: DataBaseStore.shared.viewContext)
            let categoryVC = CategoryViewController(
                trackerCategoryStore: categoryStore,
                selectedCategory: selectedCategory
            )
            categoryVC.delegate = self
            let navController = UINavigationController(rootViewController: categoryVC)
            present(navController, animated: true)
        case 1:
            let scheduleVC = SheduleScreen()
            scheduleVC.delegate = self
            scheduleVC.selectedDays = selectedSchedule
            let navController = UINavigationController(rootViewController: scheduleVC)
            present(navController, animated: true)
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource

extension CreateHabitScreen: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : UIColor(resource: .yBlackDay)}
        
        if indexPath.row == 0, let category = selectedCategory {
            cell.detailTextLabel?.text = category
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17)
        } else if indexPath.row == 1, !selectedSchedule.isEmpty {
            let scheduleText = formatScheduleText(selectedSchedule)
            cell.detailTextLabel?.text = scheduleText
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17)
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.row == 0 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: .greatestFiniteMagnitude)
        }
        
        cell.backgroundColor = .clear
        
        return cell
    }
}

// MARK: - UICollectionViewDataSource

extension CreateHabitScreen: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? AppData.emojis.count : AppData.colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.emojiCellIdentifier, for: indexPath) as? EmojiCell
            else {
                return UICollectionViewCell()
            }
            cell.configure(with: AppData.emojis[indexPath.item])
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.colorCellIdentifier, for: indexPath) as? ColorCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: AppData.colors[indexPath.item])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.headerIdentifier, for: indexPath) as? EmojiAndColorsHeaderView else {return UICollectionReusableView()}
        
        if indexPath.section == 0 {
            header.configure(with: "Emoji")
        } else {
            header.configure(with: "Цвет")
        }
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CreateHabitScreen: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath:IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 18)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0{
            selectedEmoji = AppData.emojis[indexPath.item]
            deselectAllItems(in: collectionView, forSection: 0, except: indexPath)
        } else {
            selectedColor = AppData.colors[indexPath.item]
            deselectAllItems(in: collectionView, forSection: 1, except: indexPath)
            
        }
        updateActionButtonState()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 24, left: 0, bottom: 16, right: 0)
        } else {
            return UIEdgeInsets(top: 42, left: 0, bottom: 0, right: 0)
        }
    }
    private func deselectAllItems(in collectionView: UICollectionView, forSection section: Int, except selectedIndexPath: IndexPath) {
        for item in 0..<collectionView.numberOfItems(inSection: section) {
            let indexPath = IndexPath(item: item, section: section)
            if indexPath != selectedIndexPath {
                collectionView.deselectItem(at: indexPath, animated: false)
                if let cell = collectionView.cellForItem(at: indexPath) {
                    cell.isSelected = false
                }
            }
        }
    }
}

// MARK: - Delegate Methods
extension CreateHabitScreen: CategorySelectionDelegate {
    func didSelectCategory(_ category: String) {
        selectedCategory = category
        optionsTableView.reloadData()
        updateActionButtonState()
    }
}
extension CreateHabitScreen: ScheduleSelectionDelegate {
    func didSelectSchedule(_ schedule: [Weekday]) {
        selectedSchedule = schedule
        optionsTableView.reloadData()
        updateActionButtonState()
    }
}
extension CreateHabitScreen: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

#Preview {
    CreateHabitScreen()
}
