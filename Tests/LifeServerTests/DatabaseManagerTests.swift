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
    
    func testInitialization() {
        if FileManager.default.fileExists(atPath: DatabaseManagerTests.databaseUrl.path) {
            try! FileManager.default.removeItem(at: DatabaseManagerTests.databaseUrl)
        }
        let _ = DatabaseManager(with: DatabaseManagerTests.databaseUrl)
        XCTAssertTrue(FileManager.default.fileExists(atPath: DatabaseManagerTests.databaseUrl.path))
    }
    
    func testCreateUser() {
        let userId = 123
        let userData = UserData(userName: "Test", userId: userId, color: .init(from: 0xaabbccdd))
        
        let disposeBag = DisposeBag()
        let databaseManager = DatabaseManager(with: DatabaseManagerTests.databaseUrl)
        let interactor = databaseManager.assembleInteractions(disposeBag: disposeBag)
        
        interactor.userDatabase?.store(userData: userData).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(): ()
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
    
    func testStoreWithSameUserId() {
        let userId = 678
        let userData1 = UserData(userName: "user1", userId: userId, color: .init(from: 0xdeadbeef))
        let userData2 = UserData(userName: "user2", userId: userId, color: .init(from: 0x12345678))
        
        let disposeBag = DisposeBag()
        let databaseManager = DatabaseManager(with: DatabaseManagerTests.databaseUrl)
        let interactor = databaseManager.assembleInteractions(disposeBag: disposeBag)
        
        interactor.userDatabase?.store(userData: userData1).observe { result in
            switch result {
            case .error(_): XCTFail()
            case .value(): ()
            }
        }
        
        interactor.userDatabase?.store(userData: userData2).observe { result in
            switch result {
            case .error(_): ()
            case .value(): XCTFail()
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
    }
    
    static var allTests = [
        ("testInitialization", testInitialization),
        ("testCreateUser", testCreateUser),
        ("testStoreWithSameUserId", testStoreWithSameUserId),
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
