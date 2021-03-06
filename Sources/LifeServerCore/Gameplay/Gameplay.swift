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
import RxSwift
import RxCocoa

class Gameplay {
    let onNewCycle = PublishSubject<Int>()
    let gameField: GameField
    var cycle = 0
    
    init(fieldWidth: Int, fieldHeight: Int, updatePeriod: TimeInterval) {
        self.gameField = GameField(fieldWidth, fieldHeight)
        
        updateTimer = .scheduledTimer(withTimeInterval: updatePeriod, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.cycle += 1
            self.gameField.updateForNewCycle()
            self.onNewCycle.onNext(self.cycle)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    func place(_ cell: Cell, for gameCycle: Int) -> Bool {
        if gameCycle == cycle && gameField.canPlaceCell(cell) {
            gameField.placeAcceptedCell(cell)
        } else if gameCycle == cycle-1 && gameField.canPlaceCellInPrevCycle(cell) {
            gameField.placeCellInPrevCycle(cell)
        } else {
            return false
        }
        return true
    }
    
    fileprivate var updateTimer: Timer?
}
