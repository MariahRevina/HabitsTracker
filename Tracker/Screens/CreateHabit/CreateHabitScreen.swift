import UIKit

final class CreateHabitScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CreateTrackerViewControllerDelegate?
    private var selectedCategory: String?
    private var selectedSchedule: [Weekday] = []
    
    // MARK: - UI Elements
    
    private let nameScreen: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "  Введите название трекера"
        textField.layer.cornerRadius = 16
        textField.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private var clearTextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .yGray
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    } ()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .yRed
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    } ()
    
    private let optionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
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
    
    private let options = ["Категория", "Расписание"]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCreateButtonState()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        view.backgroundColor = .white
        
        textField.delegate = self
        
        view.addSubview(nameScreen)
        view.addSubview(textField)
        view.addSubview(optionsTableView)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        view.addSubview(clearTextButton)
        view.addSubview(errorLabel)
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        
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
            
            textField.topAnchor.constraint(equalTo: nameScreen.bottomAnchor, constant: 38),
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            
            clearTextButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            clearTextButton.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -16),
            clearTextButton.widthAnchor.constraint(equalToConstant: 17),
            clearTextButton.heightAnchor.constraint(equalToConstant: 17),
            
            errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            optionsTableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 32),
            optionsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            optionsTableView.heightAnchor.constraint(equalToConstant: 150),
            
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
              !selectedSchedule.isEmpty else {
            print("Не все поля заполнены")
            return
        }
        
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: .systemBlue,
            shedule: selectedSchedule,
            emoji: "⭐️"
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
        
        let isReadyToCreate = !isNameEmpty && isCategorySelected && isScheduleSelected
        
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
            let categoryVC = CategoryScreen()
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
            let sortedSchedule = schedule.sorted { $0.rawValue < $1.rawValue }
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
        cell.textLabel?.textColor = .black
        
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
