import Testing
@testable import MqttSwift

struct UnitTests {
    @Test func connectPacketEncodesMQTT5Credentials() {
        let packet = MQTTPacketCodec.connectPacket(
            clientID: "client-one",
            config: MqttConfig(host: "localhost", auth: .credentials(username: "tomek", password: "coder")),
            keepAlive: 30
        )

        #expect(packet[0] == 0x10)
        #expect(packet.contains(5))
        #expect(packet.contains(0b1100_0010))
        #expect(String(bytes: packet.suffix(5), encoding: .utf8) == "coder")
    }

    @Test func publishPacketRoundTripsTextPayload() throws {
        let message = MqttMessage(topic: "test/one", message: "content", retained: true)
        let packet = MQTTPacketCodec.publishPacket(message)

        #expect(packet[0] == 0x31)
        let decoded = try MQTTPacketCodec.decodePublish(typeAndFlags: packet[0], body: Array(packet.dropFirst(2)))

        #expect(decoded == message)
    }

    @Test func topicMatcherSupportsMQTTWildcards() {
        #expect(MQTTTopicMatcher.matches(filter: "test/#", topic: "test/one/two"))
        #expect(MQTTTopicMatcher.matches(filter: "test/+/state", topic: "test/device/state"))
        #expect(!MQTTTopicMatcher.matches(filter: "test/+/state", topic: "test/device/other"))
        #expect(!MQTTTopicMatcher.matches(filter: "test/#/state", topic: "test/device/state"))
    }
}
