import XCTest
@testable import LifeServerCore

final class LifeServerCoreTests: XCTestCase {
    func testUsersManagerInit() {
        do {
            let _ = try UsersManager()
        } catch {
            XCTFail("UsersManager creation failed: \(error)")
        }
    }
    
    static var allTests = [
        ("testUsersManagerInit", testUsersManagerInit),
    ]
}
