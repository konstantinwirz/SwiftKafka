//
//  File.swift
//  
//
//  Created by Konstantin Wirz on 26.07.23.
//

import Foundation
import RDKafka

struct KafkaError : Error {
    let message: String
    let code: Int?
    
    init(message: String, code: Int? = nil) {
        self.message = message
        self.code = code
    }

}

extension KafkaError {
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
}
