// -----------------------------------------------------------------------------
//    Copyright (C) 2019 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

import XCTest
import RxSwift
import RxCocoa
@testable import LifeServerCore

final class DatabaseManagerTests: XCTestCase {
    static let databaseUrl = URL.applicationSupportDirectory.appendingPathComponent("LifeServer/testdatabase.db")
    var databaseManager: DatabaseManager!
    var interactor: DatabaseManager.Interactor!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        databaseManager = DatabaseManager(with: DatabaseManagerTests.databaseUrl)
        interactor = databaseManager.assembleInteractions(disposeBag: disposeBag)
    }
    
    override func tearDown() {
        interactor = nil
        databaseManager = nil
        try! FileManager.default.removeItem(at: DatabaseManagerTests.databaseUrl)
    }
    
    func testInitialization() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: DatabaseManagerTests.databaseUrl.path))
    }
    
    func testCreateUser() {
        let userId = 1
        let userData = UserData(userName: "Test", userId: userId, color: .init(from: 0xaabbccdd))

        interactor.userDatabase?.store(userData: userData).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData)
            }
        }
        
        interactor.userDatabase?.containsUser(with: userId).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertTrue(success)
            }
        }
        
        interactor.userDatabase?.userData(with: userId).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData)
            }
        }
    }
    
    func testStoreWithExistingUsername() {
        let userName = "duplicating"
        let userId1 = 2
        let userId2 = 3
        let userData1 = UserData(userName: userName, userId: userId1, color: .init(from: 0xdeadbeef))
        let userData2 = UserData(userName: userName, userId: userId2, color: .init(from: 0x12345678))
        
        interactor.userDatabase?.store(userData: userData1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.store(userData: userData2).observe { result in
            switch result {
            case .error(_): ()
            case .value(_): XCTFail()
            }
        }
        
        interactor.userDatabase?.containsUser(with: userName).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertTrue(success)
            }
        }
        
        interactor.userDatabase?.containsUser(with: userId1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertTrue(success)
            }
        }
        
        interactor.userDatabase?.containsUser(with: userId2).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertFalse(success)
            }
        }
        
        interactor.userDatabase?.userData(with: userName).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.userData(with: userId1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.userData(with: userId2).observe { result in
            switch result {
            case .error(_): ()
            case .value(_): XCTFail()
            }
        }
    }
    
    func testStoreWithExistingUserId() {
        let userId = 4
        let userName1 = "userName1"
        let userName2 = "userName2"
        let userData1 = UserData(userName: userName1, userId: userId, color: .init(from: 0xdeadbeef))
        let userData2 = UserData(userName: userName2, userId: userId, color: .init(from: 0x12345678))
        
        interactor.userDatabase?.store(userData: userData1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.store(userData: userData2).observe { result in
            switch result {
            case .error(_): ()
            case .value(_): XCTFail()
            }
        }
        
        interactor.userDatabase?.containsUser(with: userName1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertTrue(success)
            }
        }
        
        interactor.userDatabase?.containsUser(with: userName2).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertFalse(success)
            }
        }
        
        interactor.userDatabase?.containsUser(with: userId).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let success): XCTAssertTrue(success)
            }
        }
        
        interactor.userDatabase?.userData(with: userId).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.userData(with: userName1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.userData(with: userName2).observe { result in
            switch result {
            case .error(_): ()
            case .value(_): XCTFail()
            }
        }
    }
    
    func testUsersCount() {
        let userData1 = UserData(userName: "userName1", userId: 1, color: .init(from: 0xdeadbeef))
        let userData2 = UserData(userName: "userName2", userId: 2, color: .init(from: 0x12345678))
        
        interactor.userDatabase?.numberOfRegisteredUsers().observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let count): XCTAssertEqual(count, 0)
            }
        }
        
        interactor.userDatabase?.store(userData: userData1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData1)
            }
        }
        
        interactor.userDatabase?.numberOfRegisteredUsers().observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let count): XCTAssertEqual(count, 1)
            }
        }
        
        interactor.userDatabase?.store(userData: userData2).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let data): XCTAssertEqual(data, userData2)
            }
        }
        
        interactor.userDatabase?.numberOfRegisteredUsers().observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(let count): XCTAssertEqual(count, 2)
            }
        }
    }
    
    static var allTests = [
        ("testInitialization", testInitialization),
        ("testCreateUser", testCreateUser),
        ("testStoreWithExistingUsername", testStoreWithExistingUsername),
        ("testStoreWithExistingUserId", testStoreWithExistingUserId),
        ("testUsersCount", testUsersCount),
        ]
}

extension Color: Equatable {
    public static func == (lhs: Color, rhs: Color) -> Bool {
        return
            lhs.red == rhs.red &&
            lhs.green == rhs.green &&
            lhs.blue == rhs.blue &&
            lhs.alpha == rhs.alpha
    }
}

extension UserData: Equatable {
    public static func == (lhs: UserData, rhs: UserData) -> Bool {
        return
            lhs.userId == rhs.userId &&
            lhs.userName == rhs.userName &&
            lhs.color == rhs.color
    }
}
