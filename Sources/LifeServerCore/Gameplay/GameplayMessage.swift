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

enum GameplayMessage: Codable {
    case placeCell(cell: Cell, gameCycle: Int)
    case newGameCycle(gameCycle: Int)
}

extension GameplayMessage {
    private enum CodingKeys: String, CodingKey {
        case placeCell
        case newGameCycle
    }

    private enum AuxCodingKeys: String, CodingKey {
        case cell
        case gameCycle
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
        case .placeCell: self = try .placeCell(cell: dec(.cell), gameCycle: dec(.gameCycle))
        case .newGameCycle: self = try .newGameCycle(gameCycle: dec())
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .placeCell(let cell, let gameCycle):
            var nestedContainter = container.nestedContainer(keyedBy: AuxCodingKeys.self, forKey: .placeCell)
            try nestedContainter.encode(cell, forKey: .cell)
            try nestedContainter.encode(gameCycle, forKey: .gameCycle)
        case .newGameCycle(let gameCycle):
            try container.encode(gameCycle, forKey: .newGameCycle)
        }
    }
}
