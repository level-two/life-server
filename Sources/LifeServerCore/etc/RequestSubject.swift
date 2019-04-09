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

class RequestSubject<ValueT, ReturnT> {
    public let requestSubject = PublishSubject< (ValueT, ReplaySubject<ReturnT>) >()
    
    func request(_ val: ValueT) -> Observable<ReturnT> {
        guard requestSubject.hasObservers else { fatalError("OubtboundRequest is expected to have observer to return data") }
        let futureResult = ReplaySubject<ReturnT>.create(bufferSize: 1)
        requestSubject.onNext((val, futureResult))
        return futureResult
    }
    
    func bind(to next: RequestSubject<ValueT, ReturnT>) -> Disposable {
        return requestSubject.bind(to: next.requestSubject)
    }
}
