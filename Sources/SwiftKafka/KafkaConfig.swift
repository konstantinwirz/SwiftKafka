// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import RDKafka
import Logging


public class KafkaConfig {
    internal let handle: OpaquePointer
    internal var ownsHandle = true // after rd_kafka_new this config doesn't own the handle and therefor isn't responsible for destroying it
    
    public init(_ properties: [String:String]) throws {
        logger.trace("about to create an instance of KafkaConfig", metadata: ["method": "init"])
        
        handle = rd_kafka_conf_new()
        let errStrSize = 512
        let errStr = UnsafeMutablePointer<CChar>.allocate(capacity: errStrSize)
        defer {
            errStr.deallocate()
        }
        
        for (key, value) in properties {
            try key.withCString { keyPtr in
                try value.withCString { valuePtr in
                    let result: rd_kafka_conf_res_t = rd_kafka_conf_set(self.handle, keyPtr, valuePtr, errStr, errStrSize)
                    logger.debug("executed rd_kafka_conf_set", metadata: ["result": "\(result.rawValue)", "key": "\(key)", "value": "\(value)"])
                    if result != RD_KAFKA_CONF_OK {
                        throw KafkaError(String(validatingUTF8: errStr)!)
                    }
                }
            }
        }
        
        logger.debug("created an instance of \(NSStringFromClass(type(of: self)))")
    }
    
    deinit {
        if ownsHandle {
            rd_kafka_conf_destroy(handle)
            logger.debug("destroyed config")
        }
    }
}

public extension [String:String] {
    func asKafkaConfig() throws -> KafkaConfig {
        try KafkaConfig(self)
    }
}
