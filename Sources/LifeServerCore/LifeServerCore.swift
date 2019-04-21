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

import Foundation
import RxSwift
import RxCocoa


open class LifeServerCore {
    public enum LifeServerCoreError: Error {
        case failedGetApplicationSupportDirectory
    }
    
    let fieldWidth = 20
    let fieldHeight = 20
    let updatePeriod = TimeInterval(5)
    
    public init() throws {
        guard let appDataDirectory = URL.applicationSupportDirectory?.appendingPathComponent("LifeServer/")
            else { throw LifeServerCoreError.failedGetApplicationSupportDirectory }
        
        if !FileManager.default.fileExists(atPath: appDataDirectory.path) {
            try FileManager.default.createDirectory(at: appDataDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        
        databaseUrl = appDataDirectory.appendingPathComponent("database.db")
        assembleInteractions()
    }
    
    let databaseUrl: URL
    lazy var server = Server()
    lazy var database = DatabaseManager(with: databaseUrl)
    lazy var sessionManager = SessionManager(database: database)
    lazy var usersManager = UsersManager(database: database)
    lazy var chat = Chat(userInfoProvider: usersManager, sessionInfoProvider: sessionManager, chatDatabase: database)
    lazy var gameplay = Gameplay(fieldWidth: fieldWidth, fieldHeight: fieldHeight, updatePeriod: updatePeriod)
    let disposeBag = DisposeBag()
}
