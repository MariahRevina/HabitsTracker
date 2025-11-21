import UIKit

final class EmojiCell: UICollectionViewCell {
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    private lazy var selectedBack: UIView = {
        let view = UIView()
        view.backgroundColor = .yLightGray
        view.layer.cornerRadius = 16
        view.isHidden = true
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override var isSelected: Bool {
        didSet {
            selectedBack.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder:NSCoder) {
        fatalError("No Storyboard is used in this project")
    }
    
    private func setupUI() {
        contentView.addSubview(selectedBack)
        contentView.addSubview(emojiLabel)
        
    NSLayoutConstraint.activate([
        selectedBack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        selectedBack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        selectedBack.widthAnchor.constraint(equalToConstant: 52),
        selectedBack.heightAnchor.constraint(equalToConstant: 52),
        
        emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        emojiLabel.widthAnchor.constraint(equalToConstant: 32),
        emojiLabel.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
    
    func configure(with emoji: String) {
        emojiLabel.text = emoji
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
}
