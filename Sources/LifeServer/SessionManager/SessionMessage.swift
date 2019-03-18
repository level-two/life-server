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

enum SessionMessage: Codable {
    case createUser(user: User)
    case login(userName: String)
    case logout(userName: String)
}

extension SessionMessage {
    private enum CodingKeys: String, CodingKey {
        case createUser
        case login
        case logout
    }
    
    private enum AuxCodingKeys: String, CodingKey {
        case user
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
        case .login:              self = try .login(userName: dec())
        case .logout:             self = try .logout(userName: dec())
        case .createUser:         self = try .createUser(user: dec())
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .login(let userName):
            try container.encode(userName, forKey:.login)
        case .logout(let userName):
            try container.encode(userName, forKey:.logout)
        case .createUser(let user):
            try container.encode(user, forKey:.createUser)
        }
    }
}
