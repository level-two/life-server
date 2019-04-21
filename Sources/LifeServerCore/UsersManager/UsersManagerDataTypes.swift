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
    var userId: UserId
    var userName: String
    var color: Color
}

struct Color: Codable {
    let red, green, blue, alpha: Double
}

extension Color {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let r = try container.decode(Int.self)
        let g = try container.decode(Int.self)
        let b = try container.decode(Int.self)
        let a = try container.decode(Int.self)
        
        red = Double(r)/255
        green = Double(g)/255
        blue = Double(b)/255
        alpha = Double(a)/255
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(Int(red*255))
        try container.encode(Int(green*255))
        try container.encode(Int(blue*255))
        try container.encode(Int(alpha*255))
    }
}
