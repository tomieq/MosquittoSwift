
public final class MqttClient: Sendable {
    private let core = MqttClientCore()

    public init() {}

    public func connect(config: MqttConfig) async throws {
        try await self.core.connect(config: config)
    }

    public func send(_ message: MqttMessage) async throws {
        try await self.core.send(message)
    }

    public func subscribe(to topic: String, listener: @escaping @Sendable (MqttMessage) -> Void) async throws {
        try await self.core.subscribe(to: topic, listener: listener)
    }

    public func disconnect() async {
        await self.core.disconnect()
    }
}
