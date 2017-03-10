//
//  Socket.swift
//  SnackTracker
//
//  Created by Terry Latanville on 2017-03-09.
//
//

    import Foundation

public extension MySQL {
    public final class Socket {
/*
        private class Constants {
            static let headerLength: Int8 = 3
        }
        
        private let socketDescriptor: Int32
        private var bytesAvailable: Int
        private var lastErrorUserInfo: [String : Any] {
            return [
                "TODO: (TL) ERROR" : String(cString:UnsafePointer(strerror(errno)))
            ]
        }
        
        public init(host: Host, port: Int) throws {
            // TODO: (TL) ...
            print("NO OP")
            bytesAvailable = 0
            
            #if os(macOS)
                /*
                 // macOS - $ man socket
                 
                 // int domain
                 PF_LOCAL        Host-internal protocols, formerly called PF_UNIX,
                 PF_UNIX         Host-internal protocols, deprecated, use PF_LOCAL,
                 PF_INET         Internet version 4 protocols,
                 PF_ROUTE        Internal Routing protocol,
                 PF_KEY          Internal key-management function,
                 PF_INET6        Internet version 6 protocols,
                 PF_SYSTEM       System domain,
                 PF_NDRV         Raw access to network device
                 
                 // int type
                 SOCK_STREAM
                 SOCK_DGRAM
                 SOCK_RAW
                 
                 // $ man 5 protocols (TL;DR /etc/protocols)
                 */
                
                socketDescriptor = socket(AF_INET, SOCK_STREAM, 0) // TODO: (TL) Dynamic protocol ID?
            #else
                socketDescriptor = socket(AF_INET, SOCK_STREAM.rawValue, 0)
            #endif
            
            guard socketDescriptor != -1 else {
                throw NSError(domain: "TODO: (TL)", code: 0, userInfo: lastErrorUserInfo)
            }
            try configure(socketDescriptor)
        }
        
        public func open() throws {
            // TODO: (TL) ...
            print("NO OP")
        }
        
        public func close() throws {
            // TODO: (TL) ...
            print("NO OP")
        }
        
        // MARK: - I/O
        public func read() -> [UInt8] {
            return []
        }
        
        private func readHeader() throws -> (sequence: Int, length: UInt32) {
            
            return (0, 0)
        }
        
        private func readData(to count: Int) throws -> [UInt8] {
            var buffer = [UInt8](repeating: 0, count: count)
            var bytesRead = 0
            while bytesRead < count {
                /*
                 Flags (last parameter)
                 MSG_OOB        process out-of-band data
                 MSG_PEEK       peek at incoming message
                 MSG_WAITALL    wait for full request or error
                 */
                bytesRead += recv(socketDescriptor, &buffer + bytesRead, count - bytesRead, 0)
                if bytesRead <= 0 {
                    // Wait longer?
                    throw NSError(domain: "TODO: (TL)", code: 0, userInfo: lastErrorUserInfo)
                }
            }
            return buffer
        }
        
        // MARK: - Helper Functions
        private func configure(_ socketDescriptor: Int32) throws {
            /*
             var value: Int32
             guard setsockopt(socketDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
             throw NSError(domain: "TODO: (TL)", code: 0, userInfo: lastErrorUserInfo)
             }
             guard setsockopt(socketDescriptor, SOL_SOCKET, SO_KEEPALIVE, &value, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
             throw NSError(domain: "TODO: (TL)", code: 0, userInfo: lastErrorUserInfo)
             }
             
             
             let hostIP = try getHostIP(host)
             
             #if os(Linux)
             
             // bind socket to host and port
             addr = sockaddr_in(
             sin_family: sa_family_t(AF_INET),
             sin_port: Socket.porthtons(in_port_t(port)),
             sin_addr: in_addr(s_addr: inet_addr(hostIP)),
             sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
             
             signal(SIGPIPE, SIG_IGN);
             
             #else
             
             addr = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
             sin_family: sa_family_t(AF_INET),
             sin_port: Socket.porthtons(in_port_t(port)),
             sin_addr: in_addr(s_addr: inet_addr(hostIP)),
             sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
             
             guard setsockopt(self.s, SOL_SOCKET,  SO_NOSIGPIPE, &value,
             socklen_t(MemoryLayout<Int32>.size)) != -1 else {
             throw SocketError.setSockOptFailed(Socket.descriptionOfLastError())
             }
             
             #endif
             }
             */
        }
         */
    }
}
