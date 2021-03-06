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
import PromiseKit

enum ChatError: Error {
    case notLoggedIn
    case logFileInvalidHandler
    case invalidChatMessagesRequest
    case invalidChatMessage
}

class Chat {
    init(userInfoProvider: UserInfoProvider, sessionInfoProvider: SessionInfoProvider, chatDatabase: ChatDatabase) {
        self.userInfoProvider = userInfoProvider
        self.sessionInfoProvider = sessionInfoProvider
        self.chatDatabase = chatDatabase
    }

    let userInfoProvider: UserInfoProvider
    let sessionInfoProvider: SessionInfoProvider
    let chatDatabase: ChatDatabase
}
