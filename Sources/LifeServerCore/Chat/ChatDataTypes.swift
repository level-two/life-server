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

enum ChatMessageDataError: Error {
    case decodeError
}

struct ChatMessageData: Codable {
    var messageId: Int
    var userId: UserId
    var text: String
    
    init(messageId: Int, userId: UserId, text: String) {
        self.messageId = messageId
        self.userId = userId
        self.text = text
    }

    init(userId: UserId, text: String) {
        self.messageId = -1
        self.userId = userId
        self.text = text
    }
}
