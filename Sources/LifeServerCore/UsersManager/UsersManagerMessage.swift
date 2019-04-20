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

enum UsersManagerMessage: Codable {
    case createUser(userName: String, color: Color)
    case createUserSuccess(userData: UserData)
    case createUserError(error: String)
}

extension UsersManagerMessage {
    private enum CodingKeys: String, CodingKey {
        case createUser
        case createUserSuccess
        case createUserError
    }

    private enum AuxCodingKeys: String, CodingKey {
        case userName
        case color
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
        case .createUser: self = try .createUser(userName: dec(.userName), color: dec(.color))
        case .createUserSuccess: self = try .createUserSuccess(userData: dec())
        case .createUserError: self = try .createUserError(error: dec())
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .createUser(let userName, let color):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .createUser)
            try nestedContainter.encode(userName, forKey: .userName)
            try nestedContainter.encode(color, forKey: .color)
        case .createUserSuccess(let userData):
            try container.encode(userData, forKey: .createUserSuccess)
        case .createUserError(let error):
            try container.encode(error, forKey: .createUserError)
        }
    }
}
