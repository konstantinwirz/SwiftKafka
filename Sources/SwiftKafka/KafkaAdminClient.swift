//
//  File.swift
//  
//
//  Created by Konstantin Wirz on 26.07.23.
//

import Foundation
import RDKafka


class KafkaAdminClient {
    private let config: KafkaConfig
    internal let handle: OpaquePointer
    
    init(config: KafkaConfig) throws {
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
            throw KafkaError(message: String(validatingUTF8: errStr)!)
        }
        
        self.handle = tmpHandle!
        self.config.ownsHandle = false
        logger.debug("created an instance of \(NSStringFromClass(type(of: self)))")
    }
    
    func fetchMetadata() throws -> KafkaMetadata {
        let metadataPtr = UnsafeMutablePointer<UnsafePointer<rd_kafka_metadata>?>.allocate(capacity: 0);
        let result = rd_kafka_metadata(handle, 1, nil, metadataPtr, 10000)
        logger.trace("got result = \(result)")
        
        guard let metadata = metadataPtr.pointee else {
            throw KafkaError(message: "couldn't fetch metadata: response containes null-pointer")
        }
        
        defer {
            rd_kafka_metadata_destroy(metadata)
        }
        
        return KafkaMetadata(metadata[0])
    }
    
    func createTopic(name: String, partionCount: Int32, replicationFactor: Int32) throws {
        let errStrSize = 512
        let errStr = UnsafeMutablePointer<CChar>.allocate(capacity: errStrSize)
        
        
        let newTopic: OpaquePointer! = name.withCString { namePtr in
            return rd_kafka_NewTopic_new(namePtr, partionCount, replicationFactor, errStr, errStrSize)
        }
        
        guard newTopic != nil else {
            throw KafkaError(message: String(ptr: errStr) ?? "failed to create an instance of NewTopic: reason unknown")
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
            throw KafkaError(message: "failed to poll the queue")
        }
        logger.debug("polled the queue")
        defer {
            rd_kafka_event_destroy(event)
        }
        
        guard rd_kafka_event_error(event) == RD_KAFKA_RESP_ERR_NO_ERROR else {
            throw KafkaError(message: String(ptr: rd_kafka_event_error_string(event))!)
        }
        
        let result = rd_kafka_event_CreateTopics_result(event)
        guard result != nil else {
            let eventName = String(ptr: rd_kafka_event_name(event))!
            throw KafkaError(message: "Expected CreateTopics_result, not \(eventName)")
        }
        
        var topicCount: Int = 0
        let _ = withUnsafeMutablePointer(to: &topicCount) {
            rd_kafka_CreateTopics_result_topics(result, $0)
        }
        
        guard topicCount == 1 else {
            throw KafkaError(message: "something went wrong while topic creation, topicCount=\(topicCount)")
        }
        
        
        //rd_kafka_CreateTopics_result_topics(<#T##result: OpaquePointer!##OpaquePointer!#>, <#T##cntp: UnsafeMutablePointer<Int>!##UnsafeMutablePointer<Int>!#>)
        
        //print("result = \(rd_kafka_event_error(event))")
       
    }
    
    deinit {
        
        rd_kafka_destroy(self.handle)
        logger.debug("destroyed rd_kafka handle")
    }
    
}

struct KafkaMetadata {
    let brokers: [Broker]
    let topics: [Topic]
    
    // broker originating this metadata
    let origBrokerId: Int32
    // name of originating broker
    let origBrokerName: String
    
    struct Broker {
        let id: Int32
        let host: String
        let port: Int
    }
    
    struct Topic {
        let name: String
        let partitions: [Partition]
        // topic error reported by broker
        let err: KafkaError?
        
    }
    
    struct Partition {
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

extension KafkaMetadata {
    init(_ metadata: rd_kafka_metadata) {
        
        dump(metadata.topic_cnt)
        
        self.brokers = (0..<metadata.broker_cnt).map { i in KafkaMetadata.Broker(metadata.brokers[Int(i)]) }
        self.topics = (0..<metadata.topic_cnt).map { i in KafkaMetadata.Topic(metadata.topics[Int(i)]) }
        self.origBrokerId = metadata.orig_broker_id
        self.origBrokerName = String(ptr: metadata.orig_broker_name) ?? ""
        
    }
}

extension KafkaMetadata.Broker {
    init(_ broker: rd_kafka_metadata_broker_t) {
        self.id = broker.id
        self.host = String(ptr: broker.host) ??  ""
        self.port = Int(broker.port)
    }
}

extension KafkaMetadata.Topic {
    init(_ topic: rd_kafka_metadata_topic_t) {
        self.name = String(ptr: topic.topic) ?? ""
        self.partitions = (0..<topic.partition_cnt).map { i in KafkaMetadata.Partition(topic.partitions[Int(i)]) }
        self.err = KafkaError(fromRdKafkaCode: topic.err)
    }
}

extension KafkaMetadata.Partition {
    init(_ partition: rd_kafka_metadata_partition_t) {
        self.id = Int(partition.id)
        self.error = KafkaError(fromRdKafkaCode: partition.err)
        self.leaderBroker = Int(partition.leader)
        self.replicas = (0..<partition.replica_cnt).map { i in Int(partition.replicas[Int(i)]) }
        self.isrs = (0..<partition.isr_cnt).map { i in Int(partition.isrs[Int(i)]) }
    }
}

extension String {
    init?(ptr: UnsafeMutablePointer<CChar>) {
        self.init(validatingUTF8: ptr)
    }
    init?(ptr: UnsafePointer<CChar>) {
        self.init(validatingUTF8: ptr)
    }
}
