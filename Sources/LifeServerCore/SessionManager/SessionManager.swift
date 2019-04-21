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
import PromiseKit

protocol SessionInfoProvider {
    func userId(for connectionId: ConnectionId) -> UserId?
    func connectionId(for userId: UserId) -> ConnectionId?
    func isLoggedIn(_ userId: UserId) -> Bool
    var connectionsForLoggedUsers: [ConnectionId]? { get }
}

class SessionManager {
    fileprivate struct SessionInfo {
        var userId: UserId?
        var connectionId: ConnectionId
    }

    init(database: UserDatabase) {
        self.database = database
    }

    let database: UserDatabase
    fileprivate let queue = DispatchQueue(label: "life.server.sessionManagerQueue", attributes: .concurrent)
    fileprivate var sessions = [SessionInfo]()
}

extension SessionManager: SessionInfoProvider {
    var connectionsForLoggedUsers: [ConnectionId]? {
        var result: [ConnectionId]?
        queue.sync { [weak self] in
            result = self?.sessions.filter { $0.userId != nil }.map { $0.connectionId }
        }
        return result
    }
    
    public func userId(for connectionId: ConnectionId) -> UserId? {
        var result: UserId?
        queue.sync { [weak self] in
            result = self?.sessions.first { $0.connectionId == connectionId }?.userId
        }
        return result
    }

    public func connectionId(for userId: UserId) -> ConnectionId? {
        var result: ConnectionId?
        queue.sync { [weak self] in
            result = self?.sessions.first { $0.userId == userId }?.connectionId
        }
        return result
    }

    public func isLoggedIn(_ userId: UserId) -> Bool {
        return sessions.contains { $0.userId == userId }
    }
}

extension SessionManager {
    func isLoggedIn(on connectionId: ConnectionId) -> Bool {
        return userId(for: connectionId) != nil
    }

    func login(_ userId: UserId, on connectionId: ConnectionId) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            guard let idx = self.sessions.firstIndex(where: {$0.connectionId == connectionId}) else { fatalError("Info data is expected to exist") }
            var sessionInfo = self.sessions[idx]
            sessionInfo.userId = userId
            self.sessions[idx] = sessionInfo
        }
    }

    func logout(_ userId: UserId, on connectionId: ConnectionId) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            guard let idx = self.sessions.firstIndex(where: {$0.connectionId == connectionId}) else { fatalError("Info data is expected to exist") }
            var sessionInfo = self.sessions[idx]
            sessionInfo.userId = nil
            self.sessions[idx] = sessionInfo
        }
    }

    func connectionEstablished(with connectionId: ConnectionId) {
        queue.async(flags: .barrier) { [weak self] in
            self?.sessions.append(.init(userId: nil, connectionId: connectionId))
        }
    }

    func connectionClosed(with connectionId: ConnectionId) {
        queue.async(flags: .barrier) { [weak self] in
            self?.sessions.removeAll { $0.connectionId == connectionId }
        }
    }
}
