
public final class MosquittoClient: Sendable {
    private let core = MosquittoClientCore()

    public init() {}

    public func connect(config: MosquittoConfig) async throws {
        try await self.core.connect(config: config)
    }

    public func send(_ message: MosquittoMessage) async throws {
        try await self.core.send(message)
    }

    public func subscribe(to topic: String, listener: @escaping @Sendable (MosquittoMessage) -> Void) async throws {
        try await self.core.subscribe(to: topic, listener: listener)
    }

    public func disconnect() async {
        await self.core.disconnect()
    }
}
