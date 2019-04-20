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

enum ChatMessage: Codable {
    case sendChatMessage(message: String)
    case chatHistoryRequest(fromId: Int, count: Int)

    case chatMessage(message: ChatMessageData)
    case chatError(error: String)
    case chatHistoryResponse(messages: [ChatMessageData])
    case chatHistoryError(error: String)
}

extension ChatMessage {
    private enum CodingKeys: String, CodingKey {
        case sendChatMessage
        case chatHistoryRequest
        case chatMessage
        case chatError
        case chatHistoryResponse
        case chatHistoryError
    }

    private enum AuxCodingKeys: String, CodingKey {
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
            return try container
                .nestedContainer(keyedBy: AuxCodingKeys.self, forKey: key)
                .decode(T.self, forKey: auxKey)
        }
        switch key {
        case .sendChatMessage:     self = try .sendChatMessage(message: dec())
        case .chatHistoryRequest:  self = try .chatHistoryRequest(fromId: dec(.fromId), count: dec(.count))
        case .chatMessage:         self = try .chatMessage(message: dec())
        case .chatError:           self = try .chatError(error: dec())
        case .chatHistoryResponse: self = try .chatHistoryResponse(messages: dec())
        case .chatHistoryError:    self = try .chatHistoryError(error: dec())
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .sendChatMessage(let message):
            try container.encode(message, forKey: .sendChatMessage)
        case .chatHistoryRequest(let fromId, let count):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .chatHistoryRequest)
            try nestedContainter.encode(fromId, forKey: .fromId)
            try nestedContainter.encode(count, forKey: .count)
        case .chatMessage(let message):
            try container.encode(message, forKey: .chatMessage)
        case .chatError(let error):
            try container.encode(error, forKey: .chatError)
        case .chatHistoryResponse(let messages):
            try container.encode(messages, forKey: .chatHistoryResponse)
        case .chatHistoryError(let error):
            try container.encode(error, forKey: .chatHistoryError)
        }
    }
}
