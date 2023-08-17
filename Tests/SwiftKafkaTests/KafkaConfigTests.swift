import XCTest
import SwiftKafka

final class SwiftConfigTests : XCTestCase {

    func testDesignatedInitializer() throws {
        let config = try KafkaConfig(["bootstrap.servers": "localhost:9092", "client.id": "swift-kafka"])
        XCTAssertEqual(config.getValue(forKey: "bootstrap.servers"), "localhost:9092")
        XCTAssertEqual(config.getValue(forKey: "client.id"), "swift-kafka")
        XCTAssertNil(config.getValue(forKey: "not.exisiting.key"))
    }

    func testConvinientInitializer() throws {
        let config = try KafkaConfig([.bootstrapServers: "localhost:9092", .clientId: "swift-kafka"])
        XCTAssertEqual(config.getValue(forKey: "bootstrap.servers"), "localhost:9092")
        XCTAssertEqual(config.getValue(forKey: "client.id"), "swift-kafka")
        XCTAssertNil(config.getValue(forKey: "not.exisiting.key"))
    }

    func testAsKafkaConfigExtension() throws {
        let config = try [.bootstrapServers: "localhost:9092", .clientId: "swift-kafka"].asKafkaConfig()
        XCTAssertEqual(config.getValue(forKey: "bootstrap.servers"), "localhost:9092")
        XCTAssertEqual(config.getValue(forKey: "client.id"), "swift-kafka")
        XCTAssertNil(config.getValue(forKey: "not.exisiting.key"))
    }

    func testAddWithUnknownKey() throws {
        XCTAssertThrowsError(try KafkaConfig().addValue("", forKey: "unknown"), "", { error in
            XCTAssert(error is KafkaError)
            // swiftlint:disable force_cast
            XCTAssertEqual((error as! KafkaError).message, "unknown configuration property")
            XCTAssertEqual((error as! KafkaError).code, -2)
            // swiftlint:enable force_cast
        })
    }

    func testAddWithCorrectKey() throws {
        let config = KafkaConfig()
        XCTAssertEqual(try config.addValue("1000", forKey: .socketTimeoutMs).getValue(forKey: .socketTimeoutMs), "1000")
    }

}
