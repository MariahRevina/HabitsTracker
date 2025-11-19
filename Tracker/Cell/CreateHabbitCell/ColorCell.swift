import UIKit

final class ColorCell: UICollectionViewCell {
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 3 : 0
            layer.cornerRadius = 8
            layer.borderColor = isSelected ? colorView.backgroundColor?.withAlphaComponent(0.3).cgColor : nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("No Storyboard is used in this project")
    }
    
    private func setupUI() {
        contentView.addSubview(colorView)
        
        
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    func configure(with color: UIColor) {
        colorView.backgroundColor = color
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
