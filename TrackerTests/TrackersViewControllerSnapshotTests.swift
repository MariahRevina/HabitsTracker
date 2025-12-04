import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    func testTrackersViewController() {
        
        let vc = TrackersViewController()
        
        vc.loadViewIfNeeded()
        
        assertSnapshot(
            of: vc,
            as: .image,
            named: "light_mode",
            record: false
        )
    }
}
