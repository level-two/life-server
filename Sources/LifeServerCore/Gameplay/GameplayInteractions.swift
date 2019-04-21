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

extension Gameplay {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, GameplayMessage)>()
        let broadcastMessage = PublishSubject<GameplayMessage>()
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> Gameplay.Interactor {
        let interactor = Gameplay.Interactor()

        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .placeCell(let cell, let cycle) = message else { return }
            
            if self.place(cell, for: cycle) {
                interactor.broadcastMessage.onNext(.placeCell(cell: cell, gameCycle: cycle))
            }
        }.disposed(by: disposeBag)
        
        onNewCycle
            .bind { interactor.broadcastMessage.onNext(.newGameCycle(gameCycle: $0)) }
            .disposed(by: disposeBag)
        return interactor
    }
}
