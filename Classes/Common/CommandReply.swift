//
//  CommandReply.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public protocol ContentLenghtable {
    static var contentLenght: Int {get}
}

public extension Common {
    struct CommandReply: Receivable {
        public let reply: UInt8
        public init(bluetoothData: Data) throws {
            reply = try bluetoothData.extract(start: 1, length: 1)
        }        
    }
    
    struct CommandReplyWithContent<T: Receivable & ContentLenghtable>: Receivable {
        public let reply: UInt8
        public let content: T
        
        public init(bluetoothData: Data) throws {
            reply = try bluetoothData.extract(start: 1, length: 1)
            content = try T.init(bluetoothData: bluetoothData)
        }
    }
}
