
public struct MosquittoMessage: Sendable, Equatable {
    public let topic: String
    public let message: String
    public let retained: Bool

    public init(topic: String, message: String, retained: Bool = false) {
        self.topic = topic
        self.message = message
        self.retained = retained
    }
}