// -----------------------------------------------------------------------------
//    Copyright (C) 2018 Yauheni Lychkouski.
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

struct Cell: Codable {
    var pos: (x: Int, y: Int)
    var userId: UserId
}

extension Cell {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        pos.x = try container.decode(Int.self)
        pos.y = try container.decode(Int.self)
        userId = try container.decode(UserId.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(Int(pos.x))
        try container.encode(Int(pos.y))
        try container.encode(Int(userId))
    }
}
