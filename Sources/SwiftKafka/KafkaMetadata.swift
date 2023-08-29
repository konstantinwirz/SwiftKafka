//
//  KafkaMetadata.swift
//  
//
//  Created by Konstantin Wirz on 29.08.23.
//

import RDKafka

public struct KafkaMetadata {
    public let brokers: [Broker]
    public let topics: [Topic]

    // broker originating this metadata
    public let origBrokerId: Int32
    // name of originating broker
    public let origBrokerName: String

    public struct Broker {
        public let id: Int32
        public let host: String
        public let port: Int
    }

    public struct Topic {
        public let name: String
        public let partitions: [Partition]
        // topic error reported by broker
        public let err: KafkaError?
    }

    public struct Partition {
        public let id: Int
        // partition error reported by broker
        public let error: KafkaError?
        public let leaderBroker: Int
        // replica brokers
        public let replicas: [Int]
        // ISR brokers
        public let isrs: [Int]
    }
}

public extension KafkaMetadata {
    init(_ metadata: rd_kafka_metadata) {
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
