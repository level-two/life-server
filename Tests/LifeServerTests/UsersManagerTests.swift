import XCTest
@testable import LifeServer

final class UsersManagerTests: XCTestCase {
    override func setUp() {
        // TBD
    }
    
    override func tearDown() {
        // TBD
    }
    
    func initTest() {
        do {
            let _ = try UsersManager()
        } catch {
            XCTFail("UsersManager creation failed: \(error)")
        }
    }

    static var allTests = [
        ("initTest", initTest),
    ]
}
