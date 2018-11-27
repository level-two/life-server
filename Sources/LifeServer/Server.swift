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
import Socket
import Dispatch

protocol ServerDelegate {
    func onConnectionEstablished(withId connectionId:Int)
    func onConnection(withId connectionId:Int, received message:[String:Any])
    func onConnectionClosed(withId connectionId:Int)
}

class Server {
    let bufferSize = 4096
    let port: Int
    var listenSocket: Socket? = nil
    var connectedSockets = [Int32: Socket]()
    let socketLockQueue = DispatchQueue(label: "com.yauheni-lychkouski.life-server.socketLockQueue", attributes:.concurrent)
    
    public var delegate = MulticastDelegate<ServerDelegate>()
    
    init(port: Int) {
        self.port = port
    }
    
    deinit {
        // Close all open sockets...
        shutdownServer()
    }
    
    func serverRunloop() {
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            do {
                // Create an IPV4 socket...
                try self.listenSocket = Socket.create(family: .inet)
                
                guard let socket = self.listenSocket else {
                    print("Unable to unwrap socket...")
                    return
                }
                
                try socket.listen(on: self.port)
                print("Listening on port: \(socket.listeningPort)")
                
                repeat {
                    do {
                        let newSocket = try socket.acceptClientConnection()
                        
                        print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                        print("Socket Signature: \(String(describing: newSocket.signature?.description))")
                        
                        // Add the new socket to the list of connected sockets...
                        self.addSocket(socket:newSocket)
                        self.serveConnection(socket:newSocket)
                        self.delegate.invoke { $0.onConnectionEstablished(withId:Int(socket.socketfd)) }
                    }
                    catch let error {
                        guard let socketError = error as? Socket.Error else {
                            print("Unexpected error...")
                            print(error)
                        }
                        
                        print("Error reported:\n \(socketError.description)")
                    }
                } while true
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    print(error)
                }
                
                print("Error reported:\n \(socketError.description)")
            }
        }
        
        DispatchQueue.main.sync {
            exit(0)
        }
    }
    
    // On Connection:
    // - Create socket with uid and start listening for incoming data in separate thread
    // - catch read events and notify delegates
    // - catch connection closing, errors or timeout and close and remove socket from list
    // - perform write on demand (should it be blocking or non-blocking? error handling?)
    
    
    
    
    func serveConnection(socket: Socket) {
        
        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self, socket] in
            var shouldKeepRunning = true
            var readData = Data(capacity: self.bufferSize)
            do {
                try socket.write(from: "Hello, type 'QUIT' to end session\nor 'SHUTDOWN' to stop server.\n")
                
                let bytesRead = try socket.read(into: &readData)
                if bytesRead > 0 {
                    guard let response = String(data: readData, encoding: .utf8) else {
                        print("Error decoding response...")
                        readData.count = 0
                        break
                    }
                    if response.hasPrefix(EchoServer.shutdownCommand) {
                        print("Shutdown requested by connection at \(socket.remoteHostname):\(socket.remotePort)")
                        // Shut things down...
                        self.shutdownServer()
                        return
                    }
                    
                    print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                }
                
                print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                socket.close()
                
                self.socketLockQueue.sync { [unowned self, socket] in
                    self.connectedSockets[socket.socketfd] = nil
                }
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                
                print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
            }
        }
    }
    
    public func sendMessage(usingConnection connectionId:Int, dic:[String:Any]) {
        print("TODO")
    }
    
    
    
    func addSocket(socket:Socket) {
        // Add the new socket to the list of connected sockets...
        socketLockQueue.async(flags: .barrier) { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }
    }
    
    func removeSocket(socket:Socket) {
        self.socketLockQueue.async(flags: .barrier) { [unowned self, socket] in
            self.connectedSockets.removeValue(forKey: socket.socketfd)
        }
    }
    
    func closeAllSockets() {
        self.socketLockQueue.async(flags: .barrier) { [unowned self] in {
            for socket in self.connectedSockets.values {
                socket.close()
            }
            self.connectedSockets = [:]
        }
    }
    
    func getSocket(socketfd:Int32) -> Socket? {
        var socket: Socket? = nil
        socketLockQueue.sync { [unowned self] in
            socket = self.connectedSockets[socketfd]
        }
        return socket
    }
    
    func shutdownServer() {
        print("Shutting donw server")
        
        // Close all open sockets...
        self.closeAllSockets()
        listenSocket?.close()
    }
}
