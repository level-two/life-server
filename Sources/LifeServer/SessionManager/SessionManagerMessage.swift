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

enum SessionManagerMessage: Codable {
    case login(userName: String)
    case logout(userName: String)
    case loginResponse(userData: UserData?, error: String?)
    case logoutResponse(userData: UserData?, error: String?)
}

extension SessionManagerMessage {
    private enum CodingKeys: String, CodingKey {
        case login
        case logout
        case loginResponse
        case logoutResponse
    }

    private enum AuxCodingKeys: String, CodingKey {
        case userData
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else { throw "No valid keys in: \(container)" }
        func dec<T: Decodable>() throws -> T { return try container.decode(T.self, forKey: key) }
        func dec<T: Decodable>(_ auxKey: AuxCodingKeys) throws -> T {
            return try container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: key).decode(T.self, forKey: auxKey)
        }
        switch key {
        case .login: self = try .login(userName: dec())
        case .logout: self = try .logout(userName: dec())
        case .loginResponse: self = try .loginResponse(userData: dec(.userData), error: dec(.error))
        case .logoutResponse: self = try .logoutResponse(userData: dec(.userData), error: dec(.error))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .login(let userName):
            try container.encode(userName, forKey: .login)
        case .logout(let userName):
            try container.encode(userName, forKey: .logout)
        case .loginResponse(let userData, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .loginResponse)
            try nestedContainter.encode(userData, forKey: .userData)
            try nestedContainter.encode(error, forKey: .error)
        case .logoutResponse(let userData, let error):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .logoutResponse)
            try nestedContainter.encode(userData, forKey: .userData)
            try nestedContainter.encode(error, forKey: .error)
        }
    }
}
