import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

final class MQTTTransport: @unchecked Sendable {
    private let lock = NSLock()
    private var descriptor: Int32 = -1

    func connect(host: String, port: UInt16) throws {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = socketStreamType

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, String(port), &hints, &result)
        guard status == 0 else { throw MQTTError.transport(String(cString: gai_strerror(status))) }
        defer { freeaddrinfo(result) }

        var current = result
        var lastError: String?
        while let address = current {
            let fileDescriptor = socket(address.pointee.ai_family, address.pointee.ai_socktype, address.pointee.ai_protocol)
            if fileDescriptor >= 0 {
                if DarwinBridge.connect(fileDescriptor, address.pointee.ai_addr, address.pointee.ai_addrlen) == 0 {
                    self.lock.withLock {
                        self.descriptor = fileDescriptor
                    }
                    return
                }
                lastError = String(cString: strerror(errno))
                DarwinBridge.close(fileDescriptor)
            }
            current = address.pointee.ai_next
        }

        throw MQTTError.transport(lastError ?? "Unable to connect")
    }

    func write(_ bytes: [UInt8]) throws {
        guard !bytes.isEmpty else { return }
        try self.lock.withLock {
            guard self.descriptor >= 0 else { throw MQTTError.disconnected }
            var sent = 0
            try bytes.withUnsafeBytes { buffer in
                guard let baseAddress = buffer.baseAddress else { throw MQTTError.disconnected }
                while sent < bytes.count {
                    let result = DarwinBridge.send(self.descriptor, baseAddress.advanced(by: sent), bytes.count - sent)
                    guard result > 0 else { throw MQTTError.transport(String(cString: strerror(errno))) }
                    sent += result
                }
            }
        }
    }

    func readPacket() throws -> (typeAndFlags: UInt8, body: [UInt8]) {
        let typeAndFlags = try readExact(1)[0]
        var multiplier = 1
        var remainingLength = 0
        var bytesRead = 0

        while true {
            let encodedByte = try readExact(1)[0]
            remainingLength += Int(encodedByte & 127) * multiplier
            bytesRead += 1
            guard bytesRead <= 4 else { throw MQTTError.invalidPacket }
            if (encodedByte & 128) == 0 { break }
            multiplier *= 128
        }

        return (typeAndFlags, try self.readExact(remainingLength))
    }

    func close() {
        self.lock.withLock {
            guard self.descriptor >= 0 else { return }
            DarwinBridge.shutdown(self.descriptor)
            DarwinBridge.close(self.descriptor)
            self.descriptor = -1
        }
    }

    private func readExact(_ count: Int) throws -> [UInt8] {
        guard count > 0 else { return [] }
        var bytes = [UInt8](repeating: 0, count: count)
        var received = 0

        while received < count {
            let fileDescriptor = self.lock.withLock { self.descriptor }
            guard fileDescriptor >= 0 else { throw MQTTError.disconnected }
            let result = bytes.withUnsafeMutableBytes { buffer in
                DarwinBridge.recv(fileDescriptor, buffer.baseAddress!.advanced(by: received), count - received)
            }
            if result == 0 { throw MQTTError.disconnected }
            guard result > 0 else { throw MQTTError.transport(String(cString: strerror(errno))) }
            received += result
        }

        return bytes
    }
}

private var socketStreamType: Int32 {
    #if os(Linux)
    Int32(SOCK_STREAM.rawValue)
    #else
    SOCK_STREAM
    #endif
}

private enum DarwinBridge {
    static func connect(_ descriptor: Int32, _ address: UnsafePointer<sockaddr>?, _ length: socklen_t) -> Int32 {
        #if os(Linux)
        Glibc.connect(descriptor, address, length)
        #else
        Darwin.connect(descriptor, address, length)
        #endif
    }

    static func send(_ descriptor: Int32, _ pointer: UnsafeRawPointer, _ count: Int) -> Int {
        #if os(Linux)
        Glibc.send(descriptor, pointer, count, 0)
        #else
        Darwin.send(descriptor, pointer, count, 0)
        #endif
    }

    static func recv(_ descriptor: Int32, _ pointer: UnsafeMutableRawPointer, _ count: Int) -> Int {
        #if os(Linux)
        Glibc.recv(descriptor, pointer, count, 0)
        #else
        Darwin.recv(descriptor, pointer, count, 0)
        #endif
    }

    static func shutdown(_ descriptor: Int32) {
        #if os(Linux)
        _ = Glibc.shutdown(descriptor, Int32(SHUT_RDWR))
        #else
        _ = Darwin.shutdown(descriptor, SHUT_RDWR)
        #endif
    }

    static func close(_ descriptor: Int32) {
        #if os(Linux)
        _ = Glibc.close(descriptor)
        #else
        _ = Darwin.close(descriptor)
        #endif
    }
}