//
//  KafkaErrorTests.swift
//  
//
//  Created by Konstantin Wirz on 28.07.23.
//

import XCTest
import RDKafka
@testable import SwiftKafka

final class KafkaErrorTests: XCTestCase {

    func testWithoutCode() {
        let err = KafkaError("some error")
        XCTAssertEqual(err.message, "some error")
        XCTAssertNil(err.code)
    }

    func testWithCode() {
        let err = KafkaError("some error", code: 42)
        XCTAssertEqual(err.message, "some error")
        XCTAssertEqual(err.code, 42)
    }

    func testCreateFromRdKafkaCode() throws {
        let err = try XCTUnwrap(KafkaError(fromRdKafkaCode: RD_KAFKA_RESP_ERR__BAD_MSG))
        XCTAssertEqual(err.message, "Local: Bad message format")
        XCTAssertEqual(err.code, -199)
    }

    func testCreateFromNoErrorCode() {
        XCTAssertNil(KafkaError(fromRdKafkaCode: RD_KAFKA_RESP_ERR_NO_ERROR))
    }

    func testDescriptionWithoutCode() {
        let err = KafkaError("some error")
        XCTAssertEqual(err.description, "some error")
    }

    func testDescriptionWithCode() {
        let err = KafkaError("some error", code: 42)
        XCTAssertEqual(err.description, "some error; error code = 42")
    }

    func testCreateFromRdKafkaConfigErrorCode() throws {
        let err = try XCTUnwrap(KafkaError(fromRdKafkaCode: RD_KAFKA_CONF_INVALID))
        XCTAssertEqual(err.description,
                      "Invalid configuration value or property or value not supported in this build; error code = -1")
        XCTAssertEqual(err.code, Int(RD_KAFKA_CONF_INVALID.rawValue))
    }

    func testCreateFromRdKafkaConfigNoError() {
        XCTAssertNil(KafkaError(fromRdKafkaCode: RD_KAFKA_CONF_OK))
    }
}
