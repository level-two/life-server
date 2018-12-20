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
//
// Origianl idea was taken from Colin Eberhardt's article
//  https://blog.scottlogic.com/2015/02/05/swift-events.html
//

import Foundation

public class Event<U> {
    public typealias EventHandler = (U) -> ()
    fileprivate var eventHandlers = [Invocable & TargetComparable]()
    
    public func raise(with data: U) {
        for handler in self.eventHandlers {
            handler.invoke(data: data)
        }
    }
    
    public func addHandler<T: AnyObject>(target: T, handler: @escaping (T)->EventHandler) {
        eventHandlers.append(EventHandlerWrapper(target:target, handler:handler))
    }
    
    public func removeTarget<T: AnyObject>(_ target: T) {
        eventHandlers.removeAll { $0.compareTarget(target as AnyObject) }
    }
}

private protocol Invocable: AnyObject {
    func invoke(data: Any)
}

private protocol TargetComparable: AnyObject {
    func compareTarget(_: AnyObject) -> Bool
}

private class EventHandlerWrapper<T: AnyObject, U> : Invocable & TargetComparable {
    weak var target: T?
    let handler: (T) -> (U) -> ()
    
    init(target: T?, handler: @escaping (T)->(U)->()) {
        self.target = target
        self.handler = handler
    }
    
    func invoke(data: Any) {
        guard
            let t = target,
            let udata = data as? U
            else { return }
        
        handler(t)(udata)
    }
    
    func compareTarget(_ target: AnyObject) -> Bool {
        guard let selfTarget = self.target else { return false }
        guard let compareTarget = target as? T else { return false }
        return selfTarget === compareTarget
    }
}
