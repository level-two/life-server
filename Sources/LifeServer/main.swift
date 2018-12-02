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

// TODO: Add first run initialization
// TODO: Add place to handle common things like paths and preferences

do {
    #if os(Linux)
    var url = URL(fileURLWithPath: "/var/lib")
    #elseif os(macOS)
    var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    #endif
    url.appendPathComponent("LifeServer/")

    if FileManager.default.fileExists(atPath: url.path) == false {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }
}
catch {
    print("Failed to create directory for internal files: \(error)")
}
    
let port = 1337
let server = Server(port: port)
let usersManager = UsersManager()
let sessionManager = SessionManager(withServer: server, usersManager: usersManager)
let chat: Chat?
do {
    chat = try Chat(sessionManager: sessionManager, usersManager: usersManager)
}
catch {
    print ("Failed to initialize Chat: \(error)")
}
let gameplay = Gameplay()

server.run()
dispatchMain()
