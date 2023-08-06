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
        let err = KafkaError(message: "some error")
        XCTAssertEqual(err.message, "some error")
        XCTAssertNil(err.code)
    }
    
    func testWithCode() {
        let err = KafkaError(message: "some error", code: 42)
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
}

