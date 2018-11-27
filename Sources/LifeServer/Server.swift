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
    var connectedSockets: [Socket]
    let socketLockQueue = DispatchQueue(label: "com.yauheni-lychkouski.life-server.socketLockQueue", attributes:.concurrent)
    //var stopTasks: Bool
    //var isListeningTaskRunning: Bool
    //var isConnectionTaskRunning: Bool
    public var delegate = MulticastDelegate<ServerDelegate>()
    
    init(port: Int) {
        self.port = port
        self.connectedSockets = []
    }
    
    deinit {
        // Close all open sockets...
        //shutdownServer()
    }
    
    func serverRunloop() {
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            do {
                // Create an IPV4 socket...
                try self.listenSocket = Socket.create(family: .inet)
                guard let socket = self.listenSocket else {
                    print("Failed to create listening socket...")
                    return
                }
                
                defer {
                    self.listenSocket?.close()
                    self.listenSocket = nil
                }
                
                try socket.listen(on: self.port)
                print("Listening on port: \(socket.listeningPort)")
                
                while true { // self.isServerRunning {
                    let newSocket = try socket.acceptClientConnection()
                    
                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(String(describing: newSocket.signature?.description))")
                    
                    // Add the new socket to the list of connected sockets...
                    self.addSocket(socket:newSocket)
                    self.delegate.invoke { $0.onConnectionEstablished(withId:Int(newSocket.socketfd)) }
                }
            }
            catch let error {
                if let socketError = error as? Socket.Error {
                    print("Error reported: \(socketError.description)")
                }
                else {
                    print("Unexpected error: \(error)")
                }
            }
        }
    }
    
    // On Connection:
    // - Create socket with uid and start listening for incoming data in separate thread
    // - catch read events and notify delegates
    // - catch connection closing, errors or timeout and close and remove socket from list
    // - perform write on demand (should it be blocking or non-blocking? error handling?)
    
    
    
    
    func serveConnections() {
        
        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self] in
            var readData = Data(capacity: self.bufferSize)
            do {
                // get sockets list copy
                let connectedSockets = self.getConnectedSockets()
                let (readableSockets, writeableSockets) = try Socket.checkStatus(for: connectedSockets)
                
                
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
                // remove socket
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
            self.connectedSockets.append(socket)
        }
    }
    
    func removeSocket(socket:Socket) {
        self.socketLockQueue.async(flags: .barrier) { [unowned self, socket] in {
            self.connectedSockets.removeAll(where: { $0 == socket })
        }
    }
    
    func closeAllSockets() {
        self.socketLockQueue.async(flags: .barrier) { [unowned self] in {
            for socket in self.connectedSockets {
                socket.close()
            }
            self.connectedSockets = []
        }
    }
    
    func getConnectedSockets() -> [Socket]? {
        var sockets: [Socket]?
        socketLockQueue.sync { [unowned self] in
            sockets = self.connectedSockets
        }
        return sockets
    }
    
    func shutdownServer() {
        print("Shutting donw server")
        
        // Close all open sockets...
        self.closeAllSockets()
        listenSocket?.close()
    }
}
