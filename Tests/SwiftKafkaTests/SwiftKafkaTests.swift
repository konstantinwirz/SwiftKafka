import XCTest
@testable import SwiftKafka

final class SwiftKafkaTests: XCTestCase {
    func testExample() throws {
        // XCTest Documenation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
        let config = try ["bootstrap.servers": "localhost:9092"].asKafkaConfig()
        let client = try KafkaAdminClient(config: config)
        let metadata = try client.fetchMetadata()
        
        dump(metadata)
        
        try client.createTopic(name: "barfoo-\(UUID())", partionCount: 1, replicationFactor: 1)
    }
}
