
public struct MosquittoConfig: Sendable {
    public let host: String
    public let port: UInt16
    public let auth: Auth

    public init(host: String, port: UInt16 = 1883, auth: Auth = .anonymous) {
        self.host = host
        self.port = port
        self.auth = auth
    }

    public enum Auth: Sendable, Equatable {
        case anonymous
        case credentials(username: String, password: String)
    }
}
