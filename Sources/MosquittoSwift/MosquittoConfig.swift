
public struct MosquittoConfig {
    public let host: String
    public let port: UInt16
    public let auth: Auth

    public enum Auth {
        case anonymouse
        case credentials(username: String, password: String)
    }
}