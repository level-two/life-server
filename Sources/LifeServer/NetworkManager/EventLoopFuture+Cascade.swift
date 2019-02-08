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

import NIO

extension EventLoopFuture {
    /// Fulfill the given `EventLoopPromise` with the results from this `EventLoopFuture`.
    ///
    /// This is useful when allowing users to provide promises for you to fulfill, but
    /// when you are calling functions that return their own promises. They allow you to
    /// tidy up your computational pipelines. For example:
    ///
    /// ```
    /// doWork().then {
    ///     doMoreWork($0)
    /// }.then {
    ///     doYetMoreWork($0)
    /// }.thenIfError {
    ///     maybeRecoverFromError($0)
    /// }.map {
    ///     transformData($0)
    /// }.cascade(promise: userPromise)
    /// ```
    ///
    /// - parameters:
    ///     - promise: The `EventLoopPromise` to fulfill with the results of this future.
    ///                Cascaded when provided promise is non-nil
    public func cascade(promise: EventLoopPromise<T>?) {
        guard let p = promise else { return }
        self.cascade(promise: p)
    }
}
