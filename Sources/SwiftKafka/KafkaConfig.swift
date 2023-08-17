// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import RDKafka
import Logging

public class KafkaConfig {
    internal let handle: OpaquePointer
    // after rd_kafka_new this config doesn't own the handle
    // and therefor isn't responsible for destroying it
    internal var ownsHandle = true

    // MARK: - Initializers

    public init() {
        logger.trace("about to create an instance of KafkaConfig", metadata: ["method": "init"])
        handle = rd_kafka_conf_new()
    }

    public convenience init(_ properties: [String:String]) throws {
        self.init()
        for (key, value) in properties {
            try _ = addValue(value, forKey: key)
        }
        logger.debug("created an instance of \(NSStringFromClass(type(of: self)))")
    }

    public convenience init(_ properties: [Key:String]) throws {
        try self.init(Dictionary(uniqueKeysWithValues: properties.map { key, value in (key.rawValue, value) }))
    }

    // MARK: - deinitializerx

    deinit {
        if ownsHandle {
            rd_kafka_conf_destroy(handle)
            logger.debug("destroyed handle")
        }
    }

    // MARK: - add value

    public func addValue(_ value: String, forKey key: Key) throws -> KafkaConfig {
        try addValue(value, forKey: key.rawValue)
    }

    public func addValue(_ value: String, forKey key: String) throws -> KafkaConfig {
        logger.trace("about to set the value \(value) for the key \(key)")

        let errStrSize = 512
        let errStr = UnsafeMutablePointer<CChar>.allocate(capacity: errStrSize)
        defer {
            errStr.deallocate()
        }

        try key.withCString { keyPtr in
            try value.withCString { valuePtr in
                let result: rd_kafka_conf_res_t = rd_kafka_conf_set(self.handle, keyPtr, valuePtr, errStr, errStrSize)
                    logger.debug("executed rd_kafka_conf_set",
                                 metadata: ["result": "\(result.rawValue)", "key": "\(key)", "value": "\(value)"])
                    guard result == RD_KAFKA_CONF_OK else {
                        throw KafkaError(fromRdKafkaCode: result)!
                    }
            }
        }

        logger.info("set the value \(value) for the key \(key)")
        return self
    }

    // MARK: - get value

    public func getValue(forKey key: KafkaConfig.Key) -> String? {
        self.getValue(forKey: key.rawValue)
    }

    public func getValue(forKey key: String) -> String? {
        // get value length
        do {
            let size = try getValueSize(key)

            let destinationPtr = UnsafeMutablePointer<CChar>.allocate(capacity: size)
            defer {
                destinationPtr.deallocate()
            }

            let sizePtr = UnsafeMutablePointer<Int>.allocate(capacity: 0)
            defer {
                sizePtr.deallocate()
            }

            let result = rd_kafka_conf_get(self.handle, key, destinationPtr, sizePtr)

            guard result == RD_KAFKA_CONF_OK else {
                return nil
            }

            return String(cString: destinationPtr)
        } catch {
            logger.error("unknown key = \(key), error: \(error)")
            return nil
        }
    }

    /// returns the size of the value for the given key
    /// throws if key is unknown
    private func getValueSize(_ key: String) throws -> Int {
        logger.trace("about to get the size of the value for the key \(key)")

        let sizePtr = UnsafeMutablePointer<Int>.allocate(capacity: 0)
        defer {
            sizePtr.deallocate()
        }

        let result = rd_kafka_conf_get(self.handle, key, nil, sizePtr)
        logger.debug("got result from rd_kafka_conf_get = \(result.rawValue)")

        guard result == RD_KAFKA_CONF_OK else {
            throw KafkaError(fromRdKafkaCode: result)!
        }

        return sizePtr.pointee
    }

}

public extension Dictionary where Key == KafkaConfig.Key, Value == String {
    func asKafkaConfig() throws -> KafkaConfig {
        try KafkaConfig(self)
    }
}

public extension [String:String] {
    func asKafkaConfig() throws -> KafkaConfig {
        try KafkaConfig(self)
    }
}

public extension KafkaConfig {
    enum Key : String {
        case bootstrapServers = "bootstrap.servers"
        case clientId = "client.id"
        case socketTimeoutMs = "socket.timeout.ms"
    }
}
