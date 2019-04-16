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
import LifeServerCore

let lifeServer = LifeServerCore()

var args = ArraySlice(CommandLine.arguments)

func usage() {
    print(
    """
        Usage: life-server host port

            OPTIONS:
                host: Host name or IP
                port: Listening port number
    """)
}

let arg1 = args.dropFirst().first
let arg2 = args.dropFirst(2).first

guard let host = arg1 else {
    usage()
    exit(1)
}
guard let port = arg2.flatMap(Int.init) else {
    usage()
    exit(1)
}

do {
    try lifeServer.runServer(host: host, port: port)
} catch {
    print("Failed to start server: \(error)")
    exit(1)
}

dispatchMain()
