import UIKit
import AppMetricaCore

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
        if let configuration = AppMetricaConfiguration(apiKey: "427a86f5-f835-4bdc-adf0-4ea77d6e20b2") {
            AppMetrica.activate(with: configuration)
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(resource: .yBlackDay) : .white
        }
        
        if UsDefSettings.shared.onboardingShown {
            showMainScreen()
        } else {
            showOnboarding()
        }
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func showMainScreen() {
        let tabBarVC = MainTabBarViewController(
            trackerStore: trackerStore,
            trackerRecordStore: trackerRecordStore
        )
        window?.rootViewController = tabBarVC
    }
    
    func showOnboarding() {
        let pageVC = OnboardingPageVC(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        
        pageVC.onFinishOnboarding = { [weak self] in
            UsDefSettings.shared.onboardingShown = true
            self?.showMainScreen()
        }
        
        window?.rootViewController = pageVC
    }
}
