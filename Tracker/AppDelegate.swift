import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // MARK: - Store Instances
    private lazy var trackerCategoryStore: TrackerCategoryStore = {
        TrackerCategoryStore(context: DataBaseStore.shared.viewContext)
    }()
    
    private lazy var trackerStore: TrackerStore = {
        TrackerStore(context: DataBaseStore.shared.viewContext, trackerCategoryStore: trackerCategoryStore)
    }()
    
    private lazy var trackerRecordStore: TrackerRecordStore = {
        TrackerRecordStore(context: DataBaseStore.shared.viewContext)
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        
        let tabBarController = MainTabBarViewController(
            trackerStore: trackerStore,
            trackerRecordStore: trackerRecordStore
        )
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        return true
    }
}
