import UIKit

final class MainTabBarViewController: UITabBarController {
    
    // MARK: - Properties
    private let trackerStore: TrackerStore
    private let trackerRecordStore: TrackerRecordStore
    
    // MARK: - Initializer
    init(trackerStore: TrackerStore, trackerRecordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.trackerRecordStore = trackerRecordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupViewControllers()
    }
    
    // MARK: - Private Methods
    private func setupTabBarAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .gray
        tabBar.backgroundColor = .white
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = false
        
        tabBar.layer.borderWidth = 1.0 / UIScreen.main.scale
        tabBar.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2).cgColor
        tabBar.clipsToBounds = true
    }
    
    private func setupViewControllers() {
        // Создаем TrackersViewController и передаем store'ы
        let trackersVC = TrackersViewController()
        trackersVC.trackerStore = trackerStore
        trackersVC.trackerRecordStore = trackerRecordStore
        trackerStore.delegate = trackersVC
        
        let statisticsVC = StatisticsViewController()
        
        let trackersImage = UIImage(resource: .trackersItem).withRenderingMode(.alwaysTemplate)
        let statisticsImage = UIImage(resource: .rabbitItem).withRenderingMode(.alwaysTemplate)
        
        trackersVC.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: trackersImage,
            selectedImage: nil
        )
        
        statisticsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: statisticsImage,
            selectedImage: nil
        )
        
        viewControllers = [trackersVC, statisticsVC]
    }
}
