import XCTest
@testable import SwiftKafka

final class KafkaAdminClientTests: XCTestCase {

    // ensures we use expected version of librdkafka
    func testLibRDKafkaVersion() {
        let expected = "2.2.0" // version of librdkafka in submodule
        let actual = KafkaAdminClient.libRDKafkaVersion
        XCTAssertEqual(actual, expected)
    }

    func testExample() async throws {
        let config = try ["bootstrap.servers": "localhost:9092"].asKafkaConfig()
        let client = try KafkaAdminClient(config: config)
        let metadata = try await client.fetchMetadata()
        
        dump(metadata)
        
        let topicCount = try await client.createTopic(name: "barfoo-\(UUID())", partionCount: 1, replicationFactor: 1)

        XCTAssertEqual(topicCount, 1)
    }
}
