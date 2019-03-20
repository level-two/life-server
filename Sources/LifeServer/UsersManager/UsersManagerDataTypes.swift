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

typealias UserId = Int

struct UserData: Codable {
    var userName: String
    var userId: UserId?
    var color: Color
}

struct Color: Codable {
    let r, g, b, a: CGFloat
}

extension Color {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        r = try container.decode(CGFloat.self)/255
        g = try container.decode(CGFloat.self)/255
        b = try container.decode(CGFloat.self)/255
        a = try container.decode(CGFloat.self)/255
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(Int(r*255))
        try container.encode(Int(g*255))
        try container.encode(Int(b*255))
        try container.encode(Int(a*255))
    }
}
