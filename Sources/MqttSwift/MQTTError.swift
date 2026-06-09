public enum MQTTError: Error, Sendable, Equatable {
    case invalidPacket
    case malformedString
    case connectionRefused(reasonCode: UInt8)
    case disconnected
    case transport(String)
}