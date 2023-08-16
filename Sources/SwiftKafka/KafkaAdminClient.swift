//
//  File.swift
//  
//
//  Created by Konstantin Wirz on 26.07.23.
//

import Foundation
import RDKafka


public class KafkaAdminClient {
    private let config: KafkaConfig
    internal let handle: OpaquePointer
    
    public init(config: KafkaConfig) throws {
        logger.info("about to create a \(NSStringFromClass(type(of: self))) instance")
        
        self.config = config
        
        let errStrSize = 512
        let errStr = UnsafeMutablePointer<CChar>.allocate(capacity: errStrSize)
        
        let tmpHandle = rd_kafka_new(
            RD_KAFKA_PRODUCER,
            config.handle,
            errStr,
            errStrSize)
        
        if tmpHandle == nil {
            throw KafkaError(String(validatingUTF8: errStr)!)
        }
        
        self.handle = tmpHandle!
        self.config.ownsHandle = false
        logger.debug("created an instance of \(NSStringFromClass(type(of: self)))")
    }

     deinit {   
        rd_kafka_destroy(self.handle)
        logger.debug("destroyed rd_kafka handle")
    }

     /// Returns the librdkafka's version
    public static var libRDKafkaVersion: String {
        String(cString: rd_kafka_version_str())
    }
    
    public func fetchMetadata() async throws -> KafkaMetadata {
        let metadataPtr = UnsafeMutablePointer<UnsafePointer<rd_kafka_metadata>?>.allocate(capacity: 0);
        defer {
            metadataPtr.deallocate()
        }

        let result = rd_kafka_metadata(handle, 1, nil, metadataPtr, 10000)

        guard result == RD_KAFKA_RESP_ERR_NO_ERROR else {
            throw KafkaError(fromRdKafkaCode: result)!
        }
        
        guard let metadata = metadataPtr.pointee else {
            throw KafkaError("couldn't fetch metadata: response contains null-pointer")
        }
        
        defer {
            rd_kafka_metadata_destroy(metadata)
        }
        
        return KafkaMetadata(metadata[0])
    }
    
    /// creates a topic, returns the number of topics created (0 or 1)
    public func createTopic(name: String, partionCount: Int32, replicationFactor: Int32) async throws -> Int {
        let errStrSize = 512
        let errStr = UnsafeMutablePointer<CChar>.allocate(capacity: errStrSize)
        
        let newTopic: OpaquePointer! = name.withCString { namePtr in
            return rd_kafka_NewTopic_new(namePtr, partionCount, replicationFactor, errStr, errStrSize)
        }
        
        guard newTopic != nil else {
            throw KafkaError(String(ptr: errStr) ?? "failed to create an instance of NewTopic: reason unknown")
        }
        
        defer {
            rd_kafka_NewTopic_destroy(newTopic)
        }
        
        let queue = rd_kafka_queue_new(self.handle)
        defer {
            rd_kafka_queue_destroy(queue)
        }
        
        logger.trace("about to initiate topic creation", metadata: ["topic": "\(name)"])
        let ptr = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        ptr[0] = newTopic
        rd_kafka_CreateTopics(self.handle, ptr, 1, nil, queue)
        logger.debug("initiated topic creation", metadata: ["topic": "\(name)"])
        
        logger.trace("about to poll the queue")
        let event = rd_kafka_queue_poll(queue, 5000)
        guard event != nil else {
            throw KafkaError("failed to poll the queue")
        }
        logger.debug("polled the queue")
        defer {
            rd_kafka_event_destroy(event)
        }
        
        guard rd_kafka_event_error(event) == RD_KAFKA_RESP_ERR_NO_ERROR else {
            throw KafkaError(String(ptr: rd_kafka_event_error_string(event))!)
        }
        
        let result = rd_kafka_event_CreateTopics_result(event)
        guard result != nil else {
            let eventName = String(ptr: rd_kafka_event_name(event))!
            throw KafkaError("Expected CreateTopics_result, not \(eventName)")
        }
        
        var topicCount: Int = 0
        let _ = withUnsafeMutablePointer(to: &topicCount) {
            rd_kafka_CreateTopics_result_topics(result, $0)
        }

        return topicCount       
    }

   
}

public struct KafkaMetadata {
    let brokers: [Broker]
    let topics: [Topic]
    
    // broker originating this metadata
    let origBrokerId: Int32
    // name of originating broker
    let origBrokerName: String
    
    public struct Broker {
        let id: Int32
        let host: String
        let port: Int
    }
    
    public struct Topic {
        let name: String
        let partitions: [Partition]
        // topic error reported by broker
        let err: KafkaError?
        
    }
    
    public struct Partition {
        let id: Int
        // partition error reported by broker
        let error: KafkaError?
        let leaderBroker: Int
        // replica brokers
        let replicas: [Int]
        // ISR brokers
        let isrs: [Int]
    }
}

public extension KafkaMetadata {
    init(_ metadata: rd_kafka_metadata) {
        
        dump(metadata.topic_cnt)
        
        self.brokers = (0..<metadata.broker_cnt).map { i in KafkaMetadata.Broker(metadata.brokers[Int(i)]) }
        self.topics = (0..<metadata.topic_cnt).map { i in KafkaMetadata.Topic(metadata.topics[Int(i)]) }
        self.origBrokerId = metadata.orig_broker_id
        self.origBrokerName = String(ptr: metadata.orig_broker_name) ?? ""
        
    }
}

public extension KafkaMetadata.Broker {
    init(_ broker: rd_kafka_metadata_broker_t) {
        self.id = broker.id
        self.host = String(ptr: broker.host) ??  ""
        self.port = Int(broker.port)
    }
}

public extension KafkaMetadata.Topic {
    init(_ topic: rd_kafka_metadata_topic_t) {
        self.name = String(ptr: topic.topic) ?? ""
        self.partitions = (0..<topic.partition_cnt).map { i in KafkaMetadata.Partition(topic.partitions[Int(i)]) }
        self.err = KafkaError(fromRdKafkaCode: topic.err)
    }
}

public extension KafkaMetadata.Partition {
    init(_ partition: rd_kafka_metadata_partition_t) {
        self.id = Int(partition.id)
        self.error = KafkaError(fromRdKafkaCode: partition.err)
        self.leaderBroker = Int(partition.leader)
        self.replicas = (0..<partition.replica_cnt).map { i in Int(partition.replicas[Int(i)]) }
        self.isrs = (0..<partition.isr_cnt).map { i in Int(partition.isrs[Int(i)]) }
    }
}

public extension String {
    init?(ptr: UnsafeMutablePointer<CChar>) {
        self.init(validatingUTF8: ptr)
    }
    init?(ptr: UnsafePointer<CChar>) {
        self.init(validatingUTF8: ptr)
    }
}
