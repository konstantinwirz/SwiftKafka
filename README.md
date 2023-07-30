# SwiftKafka
[![CI](https://github.com/konstantinwirz/SwiftKafka/actions/workflows/ci.yaml/badge.svg)](https://github.com/konstantinwirz/SwiftKafka/actions/workflows/ci.yaml)

[WIP] development has just started

Swift kafka library based on [librdkafka](https://github.com/confluentinc/librdkafka)

## Development

- Swift v5
- librdkafka

## Usage

### Admin API

Create a client (assuming a kafka broker is running on localhost port 9092)
```swift
let config = try ["bootstrap.servers": "localhost:9092"].asKafkaConfig()
let client = try KafkaAdminClient(config: config)
```

Fetch metadata
```swift
let metadata = try client.fetchMetadata()
```

Create topic
```swift
try client.createTopic(name: "foobar", partionCount: 1, replicationFactor: 1)
```
