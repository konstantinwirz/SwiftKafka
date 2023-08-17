//
//  KafkaError.swift
//  
//
//  Created by Konstantin Wirz on 26.07.23.
//

import Foundation
import RDKafka

public struct KafkaError : Error, CustomStringConvertible {
    public let message: String
    public let code: Int?

    public init(_ message: String, code: Int? = nil) {
        self.message = message
        self.code = code
    }

    public var description: String {
        if let code = code {
            return "\(message); error code = \(code)"
        } else {
            return message
        }
    }
}

internal extension KafkaError {
    init?(fromRdKafkaCode: rd_kafka_resp_err_t) {
        if fromRdKafkaCode == RD_KAFKA_RESP_ERR_NO_ERROR {
            return nil
        }

        if let message = rd_kafka_err2str(fromRdKafkaCode) {
            self.message = String(validatingUTF8: message) ?? "unknown error code: \(fromRdKafkaCode)"
        } else {
            self.message = "unknown error code: \(fromRdKafkaCode)"
        }

        self.code = Int(fromRdKafkaCode.rawValue)
    }

    init?(fromRdKafkaCode code: rd_kafka_conf_res_t) {
        switch code {
        case RD_KAFKA_CONF_OK:
            return nil
        case RD_KAFKA_CONF_UNKNOWN:
            self.init("unknown configuration property", code: Int(code.rawValue))
        case RD_KAFKA_CONF_INVALID:
            self.init("Invalid configuration value or property or value not supported in this build",
                      code: Int(code.rawValue))
        default:
            self.init("unknown error code: \(code)", code: Int(code.rawValue))
        }
    }
}
