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
import SwiftKuery
import SwiftKuerySQLite
import PromiseKit

protocol UserInfoProvider {
    func userData(for userId: UserId) -> Promise<UserData>
    func userData(for userName: String) -> Promise<UserData>
}

class UsersManager {
    init(database: UserDatabase) {
        self.database = database
    }

    internal let database: UserDatabase
}

extension UsersManager: UserInfoProvider {
    public func userData(for userId: UserId) -> Promise<UserData> {
        return database.userData(with: userId)
    }

    public func userData(for userName: String) -> Promise<UserData> {
        return database.userData(with: userName)
    }
}
