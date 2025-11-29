import UIKit

final class CategoryViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: CategoryViewModel
    weak var delegate: CategorySelectionDelegate?
    
    private var categoryToDelete: String?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
        tableView.layer.cornerRadius = 16
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var placeholderStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isHidden = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .star)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Привычки можно\nобъединить по смыслу"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .yBlackDay
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.backgroundColor = .yBlackDay
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.showAddCategoryScreen()
        }, for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - Initialization
    init(trackerCategoryStore: TrackerCategoryStore, selectedCategory: String? = nil) {
        self.viewModel = CategoryViewModel(
            trackerCategoryStore: trackerCategoryStore,
            selectedCategory: selectedCategory
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNavigationBar()
        viewModel.loadCategories()
        
        // Подписываемся на уведомления о долгом нажатии
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCategoryCellLongPress(_:)),
            name: NSNotification.Name("CategoryCellLongPress"),
            object: nil
        )
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        placeholderStack.addArrangedSubview(placeholderImageView)
        placeholderStack.addArrangedSubview(placeholderLabel)
        
        view.addSubview(tableView)
        view.addSubview(placeholderStack)
        view.addSubview(addCategoryButton)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: -16),
            
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupBindings() {
        viewModel.onCategoriesUpdate = { [weak self] in
            self?.updateUI()
        }
        
        viewModel.onCategorySelected = { [weak self] category in
            self?.delegate?.didSelectCategory(category)
            self?.dismiss(animated: true)
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.showErrorAlert(message: errorMessage)
        }
        
        viewModel.onShowEditDialog = { [weak self] categoryTitle in
            self?.showEditOptions(for: categoryTitle)
        }
        
        viewModel.onShowDeleteConfirmation = { [weak self] categoryTitle in
            self?.showDeleteConfirmation(for: categoryTitle)
        }
    }
    
    private func setupNavigationBar() {
        title = "Категория"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        tableView.reloadData()
        placeholderStack.isHidden = viewModel.hasCategories()
    }
    
    // MARK: - Actions
    private func showAddCategoryScreen() {
        let addCategoryVC = AddEditCategoryViewController(mode: .create)
        addCategoryVC.onCategoryCreated = { [weak self] categoryTitle in
            self?.viewModel.createCategory(with: categoryTitle)
        }
        
        let navController = UINavigationController(rootViewController: addCategoryVC)
        present(navController, animated: true)
    }
    
    @objc private func handleCategoryCellLongPress(_ notification: Notification) {
        guard let categoryTitle = notification.userInfo?["categoryTitle"] as? String else { return }
        viewModel.handleLongPress(on: categoryTitle)
    }
    
    private func showEditOptions(for categoryTitle: String) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: "Редактировать", style: .default) { [weak self] _ in
            self?.showEditCategoryScreen(for: categoryTitle)
        }
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.requestDeleteConfirmation(for: categoryTitle)
        }
        
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel)
        
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showEditCategoryScreen(for categoryTitle: String) {
        let editCategoryVC = AddEditCategoryViewController(mode: .edit(categoryTitle))
        editCategoryVC.onCategoryUpdated = { [weak self] oldTitle, newTitle in
            self?.viewModel.updateCategory(oldTitle: oldTitle, newTitle: newTitle)
        }
        
        let navController = UINavigationController(rootViewController: editCategoryVC)
        present(navController, animated: true)
    }
    
    private func showDeleteConfirmation(for categoryTitle: String) {
        categoryToDelete = categoryTitle
        
        let alert = UIAlertController(
            title: "Удалить категорию?",
            message: "Все трекеры в этой категории будут удалены. Это действие необратимо.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            guard let self = self, let categoryTitle = self.categoryToDelete else { return }
            self.viewModel.deleteCategory(with: categoryTitle)
            self.categoryToDelete = nil
        }
        
        let cancelAction = UIAlertAction(title: "Отменить", style: .cancel) { [weak self] _ in
            self?.categoryToDelete = nil
        }
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCategories()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.identifier, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let categoryTitle = viewModel.categoryTitle(at: indexPath.row) ?? ""
        let isSelected = viewModel.isCategorySelected(at: indexPath.row)
        let isLastCell = indexPath.row == viewModel.numberOfCategories() - 1
        
        cell.configure(with: categoryTitle, isSelected: isSelected, isLastCell: isLastCell)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCategory(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
        
        if indexPath.row == numberOfRows - 1 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.layer.masksToBounds = true
        } else {
            cell.layer.cornerRadius = 0
            cell.layer.masksToBounds = false
        }
    }
}
