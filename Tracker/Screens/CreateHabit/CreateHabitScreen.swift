import UIKit

final class CreateHabitScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CreateTrackerViewControllerDelegate?
    private var selectedCategory: String?
    private var selectedSchedule: [Weekday] = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private let options = ["Категория", "Расписание"]
    private enum Constants {
        static let emojiCellIdentifier = "emojiCell"
        static let colorCellIdentifier = "colorCell"
        static let headerIdentifier = "header"
    }
    
    // MARK: - UI Elements
    
    private lazy var nameScreen: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
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
        textField.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
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
        tableView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
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
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated:true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.backgroundColor = .yGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.createTracker()
        }, for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCreateButtonState()
        collectionView.allowsMultipleSelection = true
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        view.backgroundColor = .white
        
        textField.delegate = self
        
        view.addSubview(nameScreen)
        view.addSubview(scrollView)
        view.addSubview(createButton)
        view.addSubview(cancelButton)
        
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
        
        NSLayoutConstraint.activate([
            
            nameScreen.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            nameScreen.heightAnchor.constraint(equalToConstant: 22),
            
            scrollView.topAnchor.constraint(equalTo: nameScreen.bottomAnchor, constant: 24),
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
            
            createButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 4),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
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
    private func textFieldChanged() {
        updateCreateButtonState()
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
                self.textField.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
            }
        }
    }
    
    private func updateCreateButtonState() {
        let isNameEmpty = textField.text?.isEmpty ?? true
        let isCategorySelected = selectedCategory != nil
        let isScheduleSelected = !selectedSchedule.isEmpty
        let isEmojiSelected = selectedEmoji != nil
        let isColorSelected = selectedColor != nil
        let isReadyToCreate = !isNameEmpty && isCategorySelected && isScheduleSelected && isEmojiSelected && isColorSelected
        
        createButton.isEnabled = isReadyToCreate
        createButton.backgroundColor = isReadyToCreate ? .black : .gray
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

// MARK: - UITableViewDataSource

extension CreateHabitScreen: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = .yBlackDay
        
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
        updateCreateButtonState()
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
        updateCreateButtonState()
    }
}
extension CreateHabitScreen: ScheduleSelectionDelegate {
    func didSelectSchedule(_ schedule: [Weekday]) {
        selectedSchedule = schedule
        optionsTableView.reloadData()
        updateCreateButtonState()
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
