//
//  File.swift
//  
//
//  Created by Konstantin Wirz on 26.07.23.
//

import Foundation
import Logging

// global logger instance
let logger = Logger(label: "SwiftKafka") { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .trace
    return handler
}
