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
    func onConnectionEstablished(withId connectionId:Int32)
    func onConnection(withId connectionId:Int32, received message:[String:Any])
    func onConnectionClosed(withId connectionId:Int32)
}

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

class Server {
    let bufferSize = 4096
    let port: Int
    var listenSocket: Socket? = nil
    var connectedSockets: [Socket]
    
    var messagesToSend = [Int32:[Data]]()
    
    var stopTasks: Bool
    var isListeningTaskFinished: Bool
    var isConnectionTaskFinished: Bool
    
    let threadSafe = ThreadSafeHelper(withQueueName: "com.yauheni-lychkouski.life-server.socketLockQueue")
    public var delegate = MulticastDelegate<ServerDelegate>()
    
    init(port: Int) {
        self.port = port
        self.connectedSockets = []
        
        stopTasks = false
        isListeningTaskFinished = false
        isConnectionTaskFinished = false
    }
    
    deinit {
        // Close all open sockets...
        shutdownServer()
    }
    
    public func run() {
        serverRunloop()
        serveConnections()
    }
    
    func serverRunloop() {
        self.isListeningTaskFinished = true
        
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            self.isListeningTaskFinished = false
            
            do {
                // Create an IPV4 socket...
                try self.listenSocket = Socket.create(family: .inet)
                guard let socket = self.listenSocket else {
                    print("Failed to create listening socket...")
                    return
                }
                
                try socket.listen(on: self.port)
                print("Listening on port: \(socket.listeningPort)")
                
                while !self.stopTasks {
                    var newSocket: Socket
                    do {
                        newSocket = try socket.acceptClientConnection()
                    }
                    catch {
                        print("Failed to accept client connection: \(error)")
                        continue
                    }
                    
                    try newSocket.setBlocking(mode: false)
                    
                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(String(describing: newSocket.signature?.description))")
                    
                    // Add the new socket to the list of connected sockets...
                    
                    self.threadSafe.performAsyncBarrier { [unowned self, newSocket] in
                        self.connectedSockets.append(newSocket)
                    }
                    
                    self.delegate.invoke { $0.onConnectionEstablished(withId:newSocket.socketfd) }
                }
            }
            catch {
                if let socketError = error as? Socket.Error {
                    print("Error reported: \(socketError.description)")
                }
                else {
                    print("Unexpected error: \(error)")
                }
                // Shutdown server in case of listening socket errors
                self.isListeningTaskFinished = true
                self.shutdownServer()
            }
            
            self.isListeningTaskFinished = true
        }
    }
    
    func serveConnections() {
        isConnectionTaskFinished = true
        
        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self] in
            self.isConnectionTaskFinished = false
            
            while !self.stopTasks {
                var readData = Data(capacity: self.bufferSize)
                
                // get sockets list copy
                var connectedSockets = [Socket]()
                
                self.threadSafe.performSyncBarrier { [unowned self] in
                    self.connectedSockets
                        .filter({ $0.remoteConnectionClosed })
                        .forEach({ [unowned self] in
                            let socketfd = $0.socketfd
                            $0.close()
                            self.delegate.invoke { $0.onConnectionClosed(withId:socketfd) }
                        })
                    self.connectedSockets.removeAll(where: { $0.remoteConnectionClosed } )
                    
                    connectedSockets = self.connectedSockets
                }
                
                // Check connection status here
                let (readableSockets, writeableSockets) : ([Socket], [Socket])
                do {
                    (readableSockets, writeableSockets) = try Socket.checkStatus(for: connectedSockets)
                }
                catch {
                    print("Failed to check sockets statuses: \(error)")
                    continue
                }
                
                for socket in readableSockets {
                    var bytesRead = 0
                    do {
                        bytesRead = try socket.read(into: &readData)
                    }
                    catch {
                        print("Failed read data from the socket: \(error)")
                        continue
                    }
                    
                    if bytesRead > 0 {
                        var dic: [String: Any]?
                        
                        do {
                            dic = try JSONSerialization.jsonObject(with: readData, options: []) as? [String:Any]
                        } catch {
                            print("Failed to decode JSON: \(error)")
                            print("Received data: \(String(data:readData, encoding:.utf8) ?? "nil")")
                            continue
                        }
                        
                        if let msgDic = dic {
                            self.delegate.invoke { $0.onConnection(withId:socket.socketfd, received:msgDic) }
                        }
                    }
                }
                
                self.threadSafe.performSyncBarrier { [unowned self] in
                    var keysForDelete = [Int32]()
                    
                    for (socketfd, messages) in self.messagesToSend {
                        guard let socket = writeableSockets.first(where: { $0.socketfd == socketfd }),
                            let data = messages.first
                            else { continue }
                        
                        do {
                            try socket.write(from:data)
                        }
                        catch let error {
                            print("Failed to send message to the socket \(socketfd): \(error)")
                        }
                        
                        if (messages.count <= 1) {
                            keysForDelete.append(socketfd)
                        }
                        else {
                            self.messagesToSend[socketfd]?.removeFirst()
                        }
                    }
                    
                    for key in keysForDelete {
                        self.messagesToSend.removeValue(forKey: key)
                    }
                }
            }
           
            self.isConnectionTaskFinished = true
        }
    }
    
    public func sendMessage(usingConnection connectionId:Int32, dic:[String:Any]) {
        var jsonData : Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        }
        catch {
            print("Failed to serialize dictionary to JSON data: \(error)")
        }
        
        guard let data = jsonData else { return }
        
        self.threadSafe.performAsyncBarrier { [unowned self, connectionId, data] in
            if self.messagesToSend[connectionId] != nil {
                self.messagesToSend[connectionId]!.append(data)
            }
            else {
                self.messagesToSend[connectionId] = [data]
            }
        }
    }
    
    func shutdownServer() {
        print("Shutting donw server")
        
        self.stopTasks = true
        
        while (!self.isListeningTaskFinished && !self.isConnectionTaskFinished) {
            print("Waiting for all tasks to be finished")
            usleep(10000)
        }
        
        // Close all open sockets...
        self.threadSafe.performSyncBarrier { [unowned self] in
            self.connectedSockets.forEach({ $0.close() })
            self.connectedSockets = []
        }
        listenSocket?.close()
    }
}
