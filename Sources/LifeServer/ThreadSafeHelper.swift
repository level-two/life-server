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
import Dispatch

class ThreadSafeHelper {
    private let lockQueue: DispatchQueue
    
    init(withQueueName queueName:String) {
        lockQueue = DispatchQueue(label: queueName, attributes:.concurrent)
    }
    
    public func performAsyncConcurrent(closure:@escaping ()->Void) {
        lockQueue.async { closure() }
    }
    
    public func performSyncConcurrent(closure:@escaping ()->Void) {
        lockQueue.sync { closure() }
    }
    
    public func performAsyncBarrier(closure:@escaping ()->Void) {
        lockQueue.async(flags: .barrier)  { closure() }
    }
    
    public func performSyncBarrier(closure:@escaping ()->Void) {
        lockQueue.sync(flags: .barrier)  { closure() }
    }
}
