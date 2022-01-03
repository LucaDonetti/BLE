//
//  CommandReply.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

extension Bike {
    struct CommandReply: Receivable {
        let reply: UInt8
        public init(bluetoothData: Data) throws {
            self.reply = try bluetoothData.extract(start: 1, length: 1)
        }
    }
}
