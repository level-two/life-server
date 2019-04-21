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

class GameFieldArray {
    private var gameField: [[Cell?]]
    public let width: Int
    public let height: Int
    
    public init(_ width: Int, _ height: Int) {
        self.width = width
        self.height = height
        gameField = .init(repeating: .init(repeating: nil, count: height), count: width)
    }
    
    public init(with gameFieldArray: GameFieldArray) {
        self.width = gameFieldArray.width
        self.height = gameFieldArray.height
        gameField = .init(repeating: .init(repeating: nil, count: height), count: width)
        gameFieldArray.allCells().forEach(self.put)
    }
    
    subscript(x: Int, y: Int) -> Cell? {
        get { let (ix, iy) = indicesFromCyclic(x, y); return gameField[ix][iy] }
        set { let (ix, iy) = indicesFromCyclic(x, y); gameField[ix][iy] = newValue }
    }
    
    subscript(pos: (x: Int, y: Int)) -> Cell? {
        get { return self[pos.x, pos.y] }
        set { self[pos.x, pos.y] = newValue }
    }
    
    func isEmpty(at x: Int, _ y: Int) -> Bool {
        return self[x, y] == nil
    }
    
    func isEmpty(at pos: (x: Int, y: Int)) -> Bool {
        return isEmpty(at: pos.x, pos.y)
    }
    
    func put(_ cell: Cell) {
        self[cell.pos] = cell
    }
    
    func allCells() -> [Cell] {
        return gameField.reduce([], +).compactMap{$0}
    }
    
    
    private func indicesFromCyclic(_ x: Int, _ y: Int) -> (Int, Int) {
        var ix = x % width
        var iy = y % height
        if ix < 0 {
            ix = width + ix
        }
        if iy < 0 {
            iy = height + iy
        }
        return (ix, iy)
    }
    
    private func indicesFromCyclic(_ pos: (x: Int, y: Int)) -> (Int, Int) {
        return indicesFromCyclic(pos.x, pos.y)
    }
}
