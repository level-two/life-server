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

//public enum Message {
//    case placeCell(gameCycle: Int, cell: Cell)
//    case new(gameCycle: Int)
//}


enum GameplayMessage: Codable {
    case sendChatMessage(message: String)
    case getChatMessages(fromId: Int?, count: Int?)
    case chatMessage(message: ChatMessageData)
    case chatMessages(messages: [ChatMessageData]?, error: String?)
}

extension GameplayMessage {
    private enum CodingKeys: String, CodingKey {
        case sendChatMessage
        case getChatMessages
        case chatMessage
        case chatMessages
    }

    private enum AuxCodingKeys: String, CodingKey {
        case user
        case error
        case messages
        case fromId
        case count
    }

    private enum DecodeError: Error {
        case noValidKeys
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else { throw DecodeError.noValidKeys }
        func dec<T: Decodable>() throws -> T { return try container.decode(T.self, forKey: key) }
        func dec<T: Decodable>(_ auxKey: AuxCodingKeys) throws -> T {
            return try container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: key).decode(T.self, forKey: auxKey)
        }
        switch key {
        case .sendChatMessage:    self = try .sendChatMessage(message: dec())
        case .chatMessage:        self = try .chatMessage(message: dec())
        case .chatMessages:       self = try .chatMessages(messages: dec(.messages), error: dec(.error))
        case .getChatMessages:    self = try .getChatMessages(fromId: dec(.fromId), count: dec(.count))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .sendChatMessage(let message):
            try container.encode(message, forKey: .sendChatMessage)
        case .chatMessage(let message):
            try container.encode(message, forKey: .chatMessage)
        case .chatMessages(let messages, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .chatMessages)
            try nestedContainter.encode(messages, forKey: .messages)
            try nestedContainter.encode(error, forKey: .error)
        case .getChatMessages(let fromId, let count):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .getChatMessages)
            try nestedContainter.encode(fromId, forKey: .fromId)
            try nestedContainter.encode(count, forKey: .count)
        }
    }
}
