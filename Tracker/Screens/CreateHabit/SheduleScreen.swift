import UIKit

final class SheduleScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ScheduleSelectionDelegate?
    var selectedDays: [Weekday] = []
    
    // MARK: - UI Elements
    
    private lazy var weekdayTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "weekdayCell")
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .textfieldBackground : .yLightGray}
        tableView.separatorColor = .yGray
        tableView.isScrollEnabled = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        return tableView
    }()
    
    private lazy var readyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(UIColor {traits in
            traits.userInterfaceStyle == .dark ? .yBlackDay : .white}, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor {traits in
            traits.userInterfaceStyle == .dark ? .white : .yBlackDay}
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.readyButtonTapped()
        }, for: .touchUpInside)
        return button
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        view.backgroundColor = UIColor {traits in
            traits.userInterfaceStyle == .dark ? .yBlackDay : .white}
        
        view.addSubview(weekdayTableView)
        view.addSubview(readyButton)
        
        weekdayTableView.delegate = self
        weekdayTableView.dataSource = self
        setupConstraints()
        
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            
            
            weekdayTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            weekdayTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            weekdayTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            weekdayTableView.heightAnchor.constraint(equalToConstant: 525),
            
            readyButton.heightAnchor.constraint(equalToConstant: 60),
            readyButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            readyButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            readyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            
        ])
    }
    
    private func setupNavigationBar() {
        title = "Расписание"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }
    
    // MARK: - Actions
    
    private func readyButtonTapped() {
        delegate?.didSelectSchedule(selectedDays)
        dismiss(animated: true)
    }
}

extension SheduleScreen: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

extension SheduleScreen: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Weekday.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "weekdayCell", for: indexPath)
        let weekday = Weekday.allCases[indexPath.row]
        cell.textLabel?.text = weekday.rawValue
        cell.textLabel?.textAlignment = .left
        cell.backgroundColor = .clear
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let switchView = UISwitch()
        switchView.isOn = selectedDays.contains(weekday)
        
        switchView.onTintColor = .yBlue
        
        switchView.addAction(UIAction { [weak self] _ in
            if switchView.isOn {
                if !(self?.selectedDays.contains(weekday) ?? false) {
                    self?.selectedDays.append(weekday)
                }
            } else {
                self?.selectedDays.removeAll { $0 == weekday }
            }
        }, for: .valueChanged)
        
        
        cell.accessoryView = switchView
        return cell
    }
}
