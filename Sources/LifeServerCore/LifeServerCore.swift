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
    lazy var server = Server()
    lazy var database = DatabaseManager()
    lazy var sessionManager = SessionManager(database: self.database)
    lazy var usersManager = UsersManager(database: self.database)
    lazy var gameplay = Gameplay()
    lazy var chat = Chat(userInfoProvider: usersManager, sessionInfoProvider: sessionManager, chatDatabase: database)

    public init() {
        assembleInteractions()
    }
    
    let disposeBag = DisposeBag()
}
