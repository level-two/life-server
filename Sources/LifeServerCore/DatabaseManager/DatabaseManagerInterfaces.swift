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
import PromiseKit

protocol UserDatabase: class {
    func containsUser(with userId: UserId) -> Promise<Bool>
    func containsUser(with userName: String) -> Promise<Bool>
    func store(userData: UserData) -> Promise<UserData>
    func userData(with userId: UserId) -> Promise<UserData>
    func userData(with userName: String) -> Promise<UserData>
    func numberOfRegisteredUsers() -> Promise<Int>
}

protocol ChatDatabase: class {
    func store(chatMessageData: ChatMessageData) -> Promise<ChatMessageData>
    func messages(fromId: Int, toId: Int) -> Promise<[ChatMessageData]>
    func lastMessages(count: Int) -> Promise<[ChatMessageData]>
    func lastMessages(fromId: Int) -> Promise<[ChatMessageData]>
}
