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
    case loginResponseSuccess(userData: UserData)
    case loginResponseError(error: String)
    case logoutResponseSuccess(userData: UserData)
    case logoutResponseError(error: String)
}

extension SessionManagerMessage {
    private enum CodingKeys: String, CodingKey {
        case login
        case logout
        case loginResponseSuccess
        case loginResponseError
        case logoutResponseSuccess
        case logoutResponseError
    }

    private enum DecodeError: Error {
        case noValidKeys
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else { throw DecodeError.noValidKeys }
        func dec<T: Decodable>() throws -> T { return try container.decode(T.self, forKey: key) }
        switch key {
        case .login: self = try .login(userName: dec())
        case .logout: self = try .logout(userName: dec())
        case .loginResponseSuccess: self = try .loginResponseSuccess(userData: dec())
        case .loginResponseError: self = try .loginResponseError(error: dec())
        case .logoutResponseSuccess: self = try .logoutResponseSuccess(userData: dec())
        case .logoutResponseError: self = try .logoutResponseError(error: dec())
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .login(let userName):
            try container.encode(userName, forKey: .login)
        case .logout(let userName):
            try container.encode(userName, forKey: .logout)
        case .loginResponseSuccess(let userData):
            try container.encode(userData, forKey: .loginResponseSuccess)
        case .loginResponseError(let error):
            try container.encode(error, forKey: .loginResponseError)
        case .logoutResponseSuccess(let userData):
            try container.encode(userData, forKey: .logoutResponseSuccess)
        case .logoutResponseError(let error):
            try container.encode(error, forKey: .logoutResponseError)
        }
    }
}
