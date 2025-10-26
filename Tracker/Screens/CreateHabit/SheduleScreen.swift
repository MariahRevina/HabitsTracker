import UIKit

class SheduleScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ScheduleSelectionDelegate?
    var selectedDays: [Weekday] = []
    
    // MARK: - UI Elements
    
    private let weekdayTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "weekdayCell")
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        tableView.isScrollEnabled = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var readyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .yBlackDay
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
        
        view.backgroundColor = .white
        
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
        cell.textLabel?.text = weekday.name
        cell.textLabel?.textAlignment = .center
        cell.backgroundColor = .clear
        
        let switchView = UISwitch()
        switchView.isOn = selectedDays.contains(weekday)
        
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
