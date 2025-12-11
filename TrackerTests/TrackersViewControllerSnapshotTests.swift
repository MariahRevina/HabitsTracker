import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    func testTrackersVCLight() {
        let vc = TrackersViewController()
        vc.loadViewIfNeeded()
        let expectation = expectation(description: "Wait for UI loading")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        
        assertSnapshot(
            of: vc,
            as: .image(traits: .init(userInterfaceStyle: .light)),
            named: "light theme",
            record: false
        )
    }
    
    func testTrackersVCDark() {
        let vc = TrackersViewController()
        vc.loadViewIfNeeded()
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        
        assertSnapshot(
            of: vc,
            as: .image(traits: .init(userInterfaceStyle: .dark)),
            named: "dark theme",
            record: false
        )
    }
}
