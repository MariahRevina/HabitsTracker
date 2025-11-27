import UIKit

final class CategoryCell: UITableViewCell {
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .yBlackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .yGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupLongPressGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkImageView)
        contentView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24),
            
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
    }
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Configuration
    func configure(with title: String, isSelected: Bool, isLastCell: Bool = false) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isSelected
        separatorView.isHidden = isLastCell
    }
    
    // MARK: - Actions
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        // Вибрация для обратной связи
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackGenerator.impactOccurred()
        
        // Вызываем замыкание через делегат или нотификацию
        // В реальной реализации это будет передано во ViewModel
        NotificationCenter.default.post(
            name: NSNotification.Name("CategoryCellLongPress"),
            object: nil,
            userInfo: ["categoryTitle": titleLabel.text ?? ""]
        )
    }
}
