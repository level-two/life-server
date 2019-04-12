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

extension SessionManager {
    public class Interactor {
        let onMessage = PublishSubject<(ConnectionId, SessionManagerMessage)>()
        let sendMessage = PublishSubject<(ConnectionId, SessionManagerMessage)>()

        fileprivate(set) weak var loginStatusProvider: LoginStatusProvider?
    }

    public func assembleInteractions(disposeBag: DisposeBag) -> SessionManager.Interactor {
        let interactor = Interactor()
        
        interactor.onMessage.bind { [weak self] connectionId, message in
            guard let self = self else { return }
            guard case .login(let userName) = message else { return }
            
            firstly {
                self.database.containsUser(with: userName)
            }.then {
                self.login(with: userName)
            }.then {
                self.database.userData(with: userName)
            }.finally {
                interactor.sendMessage.onNext((connectionId, .loginUserResponseSuccess($0)))
            }.catch {
                interactor.sendMessage.onNext((connectionId, .loginUserResponseError(error: $0)))
            }
        }.disposed(by: disposeBag)
    
    /*
        guard uidVsCon[connectionId] != userId else {
            throw SessionManagerError.UserAlreadyLoggedIn
        }
        
        guard uidVsCon[connectionId] == kNoUserId else {
            throw SessionManagerError.AnotherUserAlreadyLoggedIn
        }
        
        guard uidVsCon.values.first(where:{$0 == userId}) == nil else {
            throw SessionManagerError.UserAlreadyLoggedInOnOtherConnection
        }
        
        threadSafe.performAsyncBarrier { [weak self] in
            self?.userIdForConnectionId[connectionId] = userId
        }
        
        // Notify client
        let message = ["LoginResponse":["user":["userId":user.userId, "userName":user.name, "color":user.color]]]
        
        server?.send(to:connectionId, message:message)
        
        // Send event
        self.userLoginEvent.raise(with: userId)
        */
        
        
        
        
        
        interactor.onMessage.bind { connectionId, message in
            guard case .logout(let userName) = message else { return }
            do {
                let userId = try self.logout(with: userName)
                interactor.sendMessage.onNext((connectionId, .logoutUserResponseSuccess(userData: userData)))
            } catch {
                interactor.sendMessage.onNext((connectionId, .logoutUserResponseError(error: error.localizedDescription)))
            }
            }.disposed(by: disposeBag)
        
        interactor.loginStatusProvider = self

        return interactor
    }
}

/*
UIApplication.shared.isNetworkActivityIndicatorVisible = true

let fetchImage = URLSession.shared.dataTask(.promise, with: url).compactMap{ UIImage(data: $0.data) }
let fetchLocation = CLLocationManager.requestLocation().lastValue

firstly {
    when(fulfilled: fetchImage, fetchLocation)
    }.done { image, location in
        self.imageView.image = image
        self.label.text = "\(location)"
    }.ensure {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }.catch { error in
        self.show(UIAlertController(for: error), sender: self)
}
*/
